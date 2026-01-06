require "test_helper"

class PoliciesControllerTest < ActionDispatch::IntegrationTest
  def teardown
    ENV.delete("APP_HOST")
    Now.reset!
  end

  def test_privacy_displays_host_and_date
    Now.override!(Time.zone.parse("2026-01-06 12:00:00"), freeze: true)
    ENV["APP_HOST"] = "posse.example.test"

    get privacy_policies_path

    assert_response :success
    assert_includes response.body, "posse.example.test"
    assert_includes response.body, "2026-01-06"
  end
end
