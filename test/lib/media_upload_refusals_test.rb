require "test_helper"

class MediaUploadRefusalsTest < ActiveSupport::TestCase
  def setup
    @item = CrosspostMedia.new(type: "image", url: "http://localhost:8765/photo-1.jpg")
    @session = Struct.new(:pds, :access_token).new("https://bsky.social", "ACCESS_JWT_PLACEHOLDER")
  end

  def test_bsky_size_refusal_is_unsupported_media
    simulate_response("bsky_media_photos", 413, '{"error":"BlobTooLarge"}') do
      error = assert_raises(PublishesCrosspost::UnsupportedMediaError) { Platforms::Bsky::UploadsImages.new.upload([@item], @session) }
      assert_equal @item, error.media
    end
  end

  def test_bsky_named_media_refusal_is_unsupported_media
    simulate_response("bsky_media_photos", 400, '{"error":"InvalidMimeType"}') do
      assert_raises(PublishesCrosspost::UnsupportedMediaError) { Platforms::Bsky::UploadsImages.new.upload([@item], @session) }
    end
  end

  def test_bsky_expired_token_does_not_drop_media
    simulate_response("bsky_media_photos", 400, '{"error":"ExpiredToken"}') do
      assert_instance_of RuntimeError, assert_raises(RuntimeError) { Platforms::Bsky::UploadsImages.new.upload([@item], @session) }
    end
  end

  def test_bsky_rate_limit_does_not_drop_media
    simulate_response("bsky_media_photos", 429, '{"error":"RateLimitExceeded"}') do
      assert_instance_of RuntimeError, assert_raises(RuntimeError) { Platforms::Bsky::UploadsImages.new.upload([@item], @session) }
    end
  end

  def test_linkedin_size_refusal_is_unsupported_media
    simulate_response("linkedin_media_photos", 413, "Too large") do
      error = assert_raises(PublishesCrosspost::UnsupportedMediaError) { Platforms::Linkedin::UploadsImages.new.upload([@item], access_token: "token", person_urn: "urn:li:person:person") }
      assert_equal @item, error.media
    end
  end

  def test_linkedin_authorization_failure_does_not_drop_media
    simulate_response("linkedin_media_photos", 401, "Unauthorized") do
      assert_instance_of RuntimeError, assert_raises(RuntimeError) { Platforms::Linkedin::UploadsImages.new.upload([@item], access_token: "token", person_urn: "urn:li:person:person") }
    end
  end

  def test_linkedin_outage_does_not_drop_media
    simulate_response("linkedin_media_photos", 503, "Unavailable") do
      assert_instance_of RuntimeError, assert_raises(RuntimeError) { Platforms::Linkedin::UploadsImages.new.upload([@item], access_token: "token", person_urn: "urn:li:person:person") }
    end
  end

  def test_mastodon_missing_media_scope_is_unretriable
    simulate_response("mastodon_media_photos", 403, '{"error":"This action is outside the authorized scopes"}') do
      error = assert_raises(PublishesCrosspost::UnretriableError) { Platforms::Mastodon::UploadsMedia.new.upload(@item, base_url: "https://mastodon.social", access_token: "token") }
      assert_includes error.message, "write:media"
    end
  end

  private

  # Inject a simulated failure into a recorded upload, retaining the real download
  # and initialization traffic. These are not recordings of live server refusals.
  def simulate_response(cassette, status, body, &block)
    tag = "simulated_#{cassette}_#{status}"
    VCR.configure do |config|
      config.before_playback(tag) do |interaction|
        next unless %w[uploadBlob dms-uploads /api/v2/media].any? { |path| interaction.request.uri.include?(path) }

        interaction.response.status.code = status
        interaction.response.body = body
      end
    end
    VCR.use_cassette(cassette, record: :none, match_requests_on: [:method, :uri], tag:, &block)
  end
end
