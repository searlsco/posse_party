require "test_helper"

class AccountsHelperTest < ActiveSupport::TestCase
  include AccountsHelper

  def test_to_credentials_label_humanizes_and_formats_acronyms
    assert_equal "API Key", to_credentials_label("api_key")
    assert_equal "Client ID", to_credentials_label("client_id")
    assert_equal "API Key Secret", to_credentials_label("api_key_secret")
    assert_equal "Callback URL", to_credentials_label("callback_url")
  end
end
