module AuthHelper
  DEFAULT_PASSWORDS = {
    "admin@example.com" => "AdminPassword!1",
    "misteruser@example.com" => "UserPass!2"
  }.freeze

  def login_as(user, password: DEFAULT_PASSWORDS.fetch(user.email) {
    raise ArgumentError, "Password required for #{user.email}. Provide explicitly via password:"
  })
    post searls_auth.login_path, params: {email: user.email, password: password}
    follow_redirect!
  end
end
