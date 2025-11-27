require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

require_relative "../lib/middleware/conditional_get_file_handler"
require_relative "../lib/middleware/notifies_admins_on_exception"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PosseParty
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_record.strict_loading_by_default = true
    config.active_record.strict_loading_mode = :n_plus_one_only

    config.mission_control.jobs.base_controller_class = "AdminController"
    config.mission_control.jobs.http_basic_auth_enabled = false

    # Sessions: prefer Rails defaults; secure cookies in production.
    config.session_store :cookie_store,
      key: "_posse_session",
      expire_after: 30.days,
      secure: Rails.env.production?

    # Add support for etag calculation for static assets (HTML/XML/XSD/JSON) we actually intend to serve from the dyno.
    # lib/middleware/conditional_get_file_handler.rb
    config.middleware.swap ActionDispatch::Static, Middleware::ConditionalGetFileHandler,
      Rails.public_path.to_s, index: "index", headers: {}

    # Notify admins on unhandled exceptions (5xx only).
    # Insert before DebugExceptions so we see the original exception before Rails rescues it.
    config.middleware.insert_before ActionDispatch::DebugExceptions, Middleware::NotifiesAdminsOnException
  end
end
