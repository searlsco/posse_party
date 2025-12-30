# syntax = docker/dockerfile:1

# Use Ruby version for base image (changes infrequently)
ARG RUBY_VERSION=3.4.8
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

EXPOSE 3000

# Start the server by default, this can be overwritten at runtime to run e.g. bin/jobs
CMD ["./bin/rails", "server"]

# Install packages needed for both base and build stages (changes very infrequently)
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y \
  curl gnupg postgresql-client libidn12 libidn-dev

# Set Rails environment
ENV RAILS_ENV=production \
  BUNDLE_WITHOUT="development:test" \
  BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Set up Node.js repository (changes very infrequently)
ARG NODE_MAJOR_VERSION=22
RUN mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Install build dependencies (changes very infrequently)
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y \
  build-essential git libpq-dev pkg-config libyaml-dev zlib1g-dev libidn-dev nodejs

# Install application gems (changes frequently)
COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install && \
  rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
  bundle exec bootsnap precompile --gemfile

# Install node modules (changes frequently)
COPY --link package.json yarn.lock ./
RUN --mount=type=cache,id=bld-yarn-cache,target=/root/.cache/yarn \
  corepack enable && \
  corepack prepare yarn@1.22.22 --activate && \
  YARN_CACHE_FOLDER=/root/.cache/yarn yarn install --frozen-lockfile

# Copy Rails application code (changes every commit)
COPY --link . .

# Create app/assets/builds directory before asset precompilation
# This is needed because .dockerignore excludes this directory, but propshaft
# needs it to exist before initialization so it can be added to the asset paths
RUN mkdir -p app/assets/builds

# Precompile bootsnap code and assets (changes every commit)
RUN bundle exec bootsnap precompile app/ lib/ && \
  NO_DATABASE_AVAILABLE=1 SECRET_KEY_BASE=asset-precompile ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Clean up build artifacts (only needed during build)
RUN rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
  chown -R rails:rails db log storage tmp
USER rails:rails

# Set additional production deployment options
ENV NODE_ENV="production"
