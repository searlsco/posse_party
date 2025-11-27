class ConfiguresSearlsAuth
  def self.configure
    new.configure
  end

  def initialize
    @determines_email_capability = DeterminesEmailCapability.new
    @generates_api_key = GeneratesApiKey.new
    @parses_env_boolean = ParsesEnvBoolean.new
  end

  def configure
    return if @parses_env_boolean.parse("NO_DATABASE_AVAILABLE", default: false)

    Searls::Auth.configure { |config| apply_settings(config) }
  end

  private

  def apply_settings(config)
    routes = Rails.application.routes.url_helpers
    email_delivery_enabled = @determines_email_capability.determine

    config.app_name = "POSSE Party"
    config.layout = "modal"
    config.redirect_path_after_register = ->(*_args) { routes.posts_path }
    config.redirect_path_after_login = ->(*_args) { routes.posts_path }
    config.redirect_path_after_settings_change = ->(*_args) { routes.settings_path }
    config.auth_methods = email_delivery_enabled ? [:password, :email_otp, :email_link] : [:password]
    config.email_verification_mode = email_delivery_enabled ? :optional : :none
    config.password_reset_enabled = email_delivery_enabled
    config.user_initializer = ->(params) { build_user(params) }
    config.validate_registration = ->(user, params, errors = []) { validate_registration(user, params, errors) }
  end

  def build_user(params)
    User.new(
      email: params[:email],
      admin: !User.exists?,
      api_key: @generates_api_key.generate
    )
  end

  def validate_registration(user, params, errors)
    [
      ("Registration is invite-only." if User.exists? && !Invite.open.for_email(params[:email]).exists?),
      ("Password can't be blank" if params[:password].blank?),
      ("Password confirmation can't be blank" if params[:password_confirmation].blank?)
    ].compact
  end
end
