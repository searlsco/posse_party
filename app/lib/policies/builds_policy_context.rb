module Policies
  class BuildsPolicyContext
    Context = Struct.new(:app_host, :updated_on, keyword_init: true)

    def build(request)
      Context.new(
        app_host: ENV["APP_HOST"].presence || request.host,
        updated_on: Now.date
      )
    end
  end
end
