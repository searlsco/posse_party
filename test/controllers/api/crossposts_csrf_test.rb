require "test_helper"

class Api::CrosspostsCsrfTest < ActionDispatch::IntegrationTest
  setup do
    @previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    @crosspost = posts(:admin_post).crossposts.create!(account: accounts(:admin_x_account), status: "ready")
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @previous_forgery_protection
  end

  def test_bearer_authenticated_update_publishes_without_a_csrf_token
    patch api_crosspost_path(@crosspost),
      params: {url: "https://x.com/example/status/123"},
      headers: {"Authorization" => "Bearer #{users(:admin).api_key}"},
      as: :json

    assert_response :success
    assert_equal "published", @crosspost.reload.status
    assert_equal "https://x.com/example/status/123", @crosspost.url
    assert_not_nil @crosspost.published_at
  end

  def test_update_without_a_bearer_token_is_rejected
    patch api_crosspost_path(@crosspost), params: {url: "https://x.com/example/status/123"}, as: :json

    assert_response :unauthorized
    assert_equal "ready", @crosspost.reload.status
  end

  def test_update_with_an_invalid_bearer_token_is_rejected
    patch api_crosspost_path(@crosspost),
      params: {url: "https://x.com/example/status/123"},
      headers: {"Authorization" => "Bearer invalid-api-key"},
      as: :json

    assert_response :unauthorized
    assert_equal "ready", @crosspost.reload.status
  end
end
