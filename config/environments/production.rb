require "active_support/core_ext/integer/time"
require_relative "../../app/lib/redirects_www_to_bare_domain"
require_relative "../../app/lib/parses_env_boolean"
require_relative "../../app/lib/configures_mailer"
require_relative "../../app/lib/identifies_ip_host"
require_relative "../../app/lib/determines_host_settings"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Redirect www subdomain to bare domain, without depending on SSL middleware order.
  config.middleware.use RedirectsWwwToBareDomain

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = {"cache-control" => "public, max-age=#{1.year.to_i}"}

  # Optional asset host; when unset, helpers emit relative asset paths.
  config.asset_host = config.action_controller.asset_host = ENV["RAILS_ASSET_HOST"].presence

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Email delivery (provider selected by MAIL_PROVIDER).
  config.action_mailer.delivery_method = ConfiguresMailer.new.configure!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Optional host allowlist: comma-separated hostnames. If unset or '*', do nothing.
  raw_hosts = ENV["RAILS_ALLOWED_HOSTS"].to_s
  if raw_hosts.present? && raw_hosts != "*"
    config.hosts = raw_hosts.split(/,\s*/)
  end
  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = {exclude: ->(request) { request.path == "/up" }}

  app_host = ENV["APP_HOST"].presence
  app_port = ENV["APP_PORT"].presence
  host_settings = DeterminesHostSettings.new.determine(
    app_host: app_host,
    app_port: app_port,
    app_private_host: ParsesEnvBoolean.new.parse("APP_PRIVATE_HOST", default: false),
    app_protocol_env: ENV["APP_PROTOCOL"].presence
  )

  # SSL: force HTTPS in production; assume SSL when forcing SSL (behind proxies).
  config.assume_ssl = config.force_ssl = host_settings.force_ssl

  if app_host
    url_options = {
      protocol: host_settings.protocol,
      host: app_host,
      port: app_port
    }.compact
    Rails.application.routes.default_url_options = config.action_mailer.default_url_options = url_options
  end
end
