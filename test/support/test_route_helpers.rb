module TestRouteHelpers
  def set_session_var(key, value)
    visit "/test/session?key=#{URI.encode_www_form_component(key)}&value=#{URI.encode_www_form_component(value)}"
  end
end
