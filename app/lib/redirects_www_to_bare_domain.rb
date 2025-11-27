# config/initializers/redirects_www_to_bare_domain.rb
class RedirectsWwwToBareDomain
  def initialize(app)
    @app = app
  end

  def call(env)
    req = ActionDispatch::Request.new(env)

    host = req.host
    return @app.call(env) unless host&.start_with?("www.")

    bare = host.sub(/\Awww\./, "")

    uri = URI.parse(req.original_url) # respects X-Forwarded-* on Heroku
    uri.host = bare

    [301, {"Location" => uri.to_s, "Content-Type" => "text/html"},
      ["Redirecting to #{Rack::Utils.escape_html(uri.to_s)}"]]
  end
end
