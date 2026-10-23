require "test_helper"

class MastodonMediaTest < ActiveJob::TestCase
  def setup
    @user = New.create(User, email: "user@example.com")
    @user.accounts.create!(platform_tag: "mastodon", label: "@testperson", credentials: vcr_secrets({
      "access_token" => nil
    }).merge("base_url" => "https://mastodon.social"))
    FetchesFeed.new.fetch!(fake_feed_from(@user, "2026-10-22-media-attachments.atom.xml"), cache: false)
  end

  def test_attaches_photos_with_descriptions
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/photos/")

    perfect_vcr_match("mastodon_media_photos") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "Two photos for the POSSE Party media test https://posseparty.com/test/media/photos/", crosspost.content
  end

  def test_attaches_a_video_once_processed
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/clip/")

    perfect_vcr_match("mastodon_media_clip") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "A short clip for the POSSE Party media test https://posseparty.com/test/media/clip/", crosspost.content
  end

  def test_posts_only_a_link_when_photos_dont_fit
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/five-photos/")

    perfect_vcr_match("mastodon_media_link_back") do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "Five photos is one too many for some platforms https://posseparty.com/test/media/five-photos/", crosspost.content
  end

  private

  def wip_crosspost_for(remote_id)
    Post.find_by(remote_id:).crossposts.first.tap { |crosspost| crosspost.update!(status: "wip") }
  end
end
