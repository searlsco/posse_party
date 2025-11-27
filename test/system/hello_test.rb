require "application_system_test_case"

class HelloTest < ApplicationSystemTestCase
  def test_root
    visit root_url
    assert_text "Log In"
  end
end
