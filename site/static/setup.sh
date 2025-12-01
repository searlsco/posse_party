#!/usr/bin/env bash
set -euo pipefail

# One-shot installer for POSSE Party (Docker Compose)
# Usage:
#   APP_HOST=your.domain.or.ip /bin/bash -c "$(curl -fsSL https://posseparty.com/setup.sh)"

TAG=${TAG:-latest}
IMAGE=${POSSE_IMAGE:-ghcr.io/searlsco/posse_party:${TAG}}

if [[ -z "${SECRET_KEY_BASE:-}" ]]; then
  SECRET_KEY_BASE=$(openssl rand -hex 64)
fi

detect_cpus() {
  nproc --all 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1
}

vcpus=$(detect_cpus)
profile="tiny"
default_web_threads=2
default_job_threads=1
default_job_concurrency=1
default_web_concurrency=0

if (( vcpus >= 5 )); then
  profile="large"
  default_web_threads=7
  default_job_threads=4
  default_job_concurrency=2
  default_web_concurrency=3
elif (( vcpus >= 3 )); then
  profile="medium"
  default_web_threads=5
  default_job_threads=3
  default_job_concurrency=1
  default_web_concurrency=2
elif (( vcpus >= 2 )); then
  profile="small"
  default_web_threads=3
  default_job_threads=2
  default_job_concurrency=1
  default_web_concurrency=0
fi

echo "Detected ${vcpus} vCPU(s); applying ${profile} concurrency defaults (WEB_CONCURRENCY=${default_web_concurrency}, WEB_THREADS=${default_web_threads}, JOB_THREADS=${default_job_threads}, JOB_CONCURRENCY=${default_job_concurrency})."

mkdir -p posse_party/bin
cd posse_party

force_ssl_default=""

cat > .env <<EOF_ENV
# Configure your installation by setting these
APP_HOST=${APP_HOST:-}

# Mailer settings (choose a provider and then uncomment/set the corresponding variables)
MAIL_PROVIDER=${MAIL_PROVIDER:-}
MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS:-}
## amazon_ses - Amazon SES
# AWS_SES_REGION=${AWS_SES_REGION:-}
# AWS_SES_ACCESS_KEY_ID=${AWS_SES_ACCESS_KEY_ID:-}
# AWS_SES_SECRET_ACCESS_KEY=${AWS_SES_SECRET_ACCESS_KEY:-}
## resend - Resend
# RESEND_API_KEY=${RESEND_API_KEY:-}
## mailgun - Mailgun
MAILGUN_API_KEY=${MAILGUN_API_KEY:-}
MAILGUN_DOMAIN=${MAILGUN_DOMAIN:-}
## postmark - Postmark
POSTMARK_API_TOKEN=${POSTMARK_API_TOKEN:-}
## sendgrid - SendGrid
SENDGRID_API_KEY=${SENDGRID_API_KEY:-}
## brevo - Brevo (Sendinblue)
BREVO_API_KEY=${BREVO_API_KEY:-}
## mailjet - Mailjet
MAILJET_API_KEY=${MAILJET_API_KEY:-}
MAILJET_API_SECRET=${MAILJET_API_SECRET:-}
## smtp - SMTP (make sure your host allows outbound SMTP!)
SMTP_HOST=${SMTP_HOST:-}
SMTP_USERNAME=${SMTP_USERNAME:-}
SMTP_PASSWORD=${SMTP_PASSWORD:-}
SMTP_PORT=${SMTP_PORT:-587}
SMTP_ENABLE_STARTTLS=${SMTP_ENABLE_STARTTLS:-true}

# You're less likely to change these
POSSE_IMAGE=${IMAGE}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
RAILS_ASSET_HOST=${RAILS_ASSET_HOST:-}
RAILS_ALLOWED_HOSTS=${RAILS_ALLOWED_HOSTS:-}

# Changing these may disable automatic HTTPS or impact security
APP_HTTP_PORT=${APP_HTTP_PORT:-80}
APP_HTTPS_PORT=${APP_HTTPS_PORT:-443}
APP_PRIVATE_HOST=${APP_PRIVATE_HOST:-false}
APP_PROTOCOL=${APP_PROTOCOL:-}
FORCE_SSL=${FORCE_SSL:-${force_ssl_default}}

# You probably don't want to change these
DATABASE_URL=${DATABASE_URL:-postgres://postgres:postgres@db:5432/posse_party_production}
RAILS_ENV=${RAILS_ENV:-production}
RAILS_LOG_LEVEL=${RAILS_LOG_LEVEL:-info}
RAILS_LOG_TO_STDOUT=${RAILS_LOG_TO_STDOUT:-enabled}
RAILS_SERVE_STATIC_FILES=${RAILS_SERVE_STATIC_FILES:-true}
WEB_THREADS=${WEB_THREADS:-${default_web_threads}}
WEB_CONCURRENCY=${WEB_CONCURRENCY:-${default_web_concurrency}}
JOB_THREADS=${JOB_THREADS:-${default_job_threads}}
JOB_CONCURRENCY=${JOB_CONCURRENCY:-${default_job_concurrency}}
SOLID_QUEUE_IN_PUMA=${SOLID_QUEUE_IN_PUMA:-false}
EOF_ENV

echo "<---- Pulling image"
docker pull "${IMAGE}"

echo "<---- Installing management scripts"
docker run --rm -u root -v "$PWD":/host "${IMAGE}" bash -lc 'source /rails/script/docker_sync_assets; copy_docker_assets /rails /host'

echo "<---- Starting services"
docker compose -f docker-compose.yml pull
docker compose -f docker-compose.yml up -d

app_host=${APP_HOST:-}
app_private=${APP_PRIVATE_HOST:-false}
app_http_port=${APP_HTTP_PORT:-80}
app_https_port=${APP_HTTPS_PORT:-443}
app_http_port_suffix="${app_http_port:+:${app_http_port}}"
app_protocol=${APP_PROTOCOL:-}

is_ip_host=false
if [[ -n "${app_host}" ]]; then
  if [[ "${app_host}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    is_ip_host=true
  elif [[ "${app_host}" =~ : ]] && [[ "${app_host}" =~ ^[0-9a-fA-F:]+$ ]]; then
    is_ip_host=true
  fi
fi

https_mode="public"
if [[ "${app_protocol}" == "http" ]]; then
  https_mode="off:protocol"
elif [[ "${app_private}" == "true" ]]; then
  https_mode="internal"
elif [[ "${is_ip_host}" == "true" ]]; then
  https_mode="off:ip"
fi

if [[ -n "${app_host}" ]]; then
  https_url="https://${app_host}"
  http_url="http://${app_host}${app_http_port_suffix}"

  case "${https_mode}" in
    off:port)
      app_url="${http_url}"
      https_status="DISABLED (APP_PROTOCOL=http)"
      access_note="Caddy serving HTTP on :${app_http_port}. HTTPS disabled because APP_PROTOCOL=http."
      ;;
    off:protocol)
      app_url="${http_url}"
      https_status="DISABLED (APP_PROTOCOL=http)"
      access_note="Caddy serving HTTP on :${app_http_port}. HTTPS disabled because APP_PROTOCOL=http."
      ;;
    off:ip)
      app_url="${http_url}"
      https_status="DISABLED (APP_HOST is an IP address; automatic TLS needs DNS)"
      access_note="Caddy serving HTTP on :${app_http_port}. Automatic certificates require a DNS hostname."
      ;;
    internal)
      app_url="${https_url}"
      https_status="ENABLED (internal certificate; expect browser warning)"
      access_note="HTTPS via Caddy with an internal certificate; HTTP also available at ${http_url}."
      ;;
    *)
      app_url="${https_url}"
      https_status="ENABLED (automatic HTTPS via Caddy for ${app_host})"
      access_note="Point DNS (A/AAAA) for ${app_host} to this server; Caddy will obtain HTTPS automatically. HTTP also available at ${http_url}."
      ;;
  esac
else
  app_url="http://localhost:${app_http_port}"
  https_status="DISABLED (no APP_HOST set)"
  access_note="Web server is serving plain HTTP on :${app_port}. App container listens on http://localhost:3000 internally."
fi

cat <<MSG

All set, you should be up and running:

  - App endpoint: ${app_url}
  - HTTPS status: ${https_status} (configurable in .env)
  - ${access_note}

Next steps:

  1. cd posse_party
  2. Edit '.env' to configure the app (set MAIL_PROVIDER and provider API keys or SMTP so POSSE Party can send email)
  3. Run lifecycle scripts in 'bin/' (e.g., restart, upgrade, backup, console, bash, logs)

Managing your install:

  - After editing .env, run ./bin/restart to apply changes
  - To upgrade the app to the latest release, run ./bin/upgrade

MSG
