Rails.application.config.after_initialize do
  next if Rails.env.production?

  # Used by lib/middleware/conditional_get_file_handler.rb
  unless ActionDispatch::FileHandler.instance_method(:find_file).parameters == [[:req, :path_info], [:keyreq, :accept_encoding]]
    raise "Our assumptions about a private method call we're making to ActionDispatch::FileHandler have been violated! Bailing."
  end
end
