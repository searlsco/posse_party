class BuildsInviteEmail
  EmailDraft = Struct.new(:subject, :body, :register_url, keyword_init: true)

  SUBJECT = "You're invited to my POSSE Party!".freeze

  def initialize(routes: Rails.application.routes, auth_routes: Searls::Auth::Engine.routes)
    @routes = routes
    @auth_routes = auth_routes
  end

  def build(invite)
    url_options = default_url_options
    base_url = @routes.url_helpers.root_url(**url_options).delete_suffix("/")
    register_url = @auth_routes.url_helpers.register_url(**url_options, email: invite.email)
    inviter_email = invite.invited_by.email

    body = <<~BODY
      #{inviter_email} has invited you to the POSSE Party instance hosted at #{base_url}, if you'd like to accept this invitation and register an account, you can do so at:

      #{register_url}
    BODY

    EmailDraft.new(subject: SUBJECT, body:, register_url:)
  end

  private

  def default_url_options
    @routes.default_url_options.presence || Rails.configuration.action_mailer.default_url_options || {}
  end
end
