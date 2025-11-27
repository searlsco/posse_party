# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  if Rails.env.production?
    allow do
      origins(/^https?:\/\/(.*\.)?posseparty\.com$/)
      resource "*",
        headers: :any,
        methods: [:head, :get, :post, :put, :patch, :options],
        expose: ["Content-Range", "Range", "ETag"],
        credentials: true
    end
  else
    allow do
      origins "*"
      resource "*", headers: :any, methods: [:head, :get, :post, :put, :patch, :options]
    end
  end
end
