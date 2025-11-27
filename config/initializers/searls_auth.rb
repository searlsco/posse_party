Rails.application.config.after_initialize do
  ConfiguresSearlsAuth.configure
end
