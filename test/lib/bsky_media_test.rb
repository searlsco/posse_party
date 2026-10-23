require "test_helper"

class BskyMediaTest < ActiveJob::TestCase
  def setup
    @user = New.create(User, email: "user@example.com")
    @user.accounts.create!(platform_tag: "bsky", label: "Test Account", credentials: vcr_secrets({
      "email" => nil,
      "password" => nil
    }))
    FetchesFeed.new.fetch!(fake_feed_from(@user, "2026-10-22-media-attachments.atom.xml"), cache: false)
  end

  def test_attaches_photos_in_place_of_the_website_card
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/photos/")

    perfect_vcr_match("bsky_media_photos", time: "2026-10-22T11:30:00Z", except: [:headers]) do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "Two photos for the POSSE Party media test 🔗", crosspost.content
  end

  def test_attaches_a_video_once_processed
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/clip/")

    perfect_vcr_match("bsky_media_clip", time: "2026-10-22T11:35:00Z", except: [:headers]) do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "A short clip for the POSSE Party media test 🔗", crosspost.content
  end

  def test_attaches_the_first_four_of_five_photos_when_best_effort
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/five-photos-best-effort/")

    perfect_vcr_match("bsky_media_best_effort", time: "2026-10-22T11:40:00Z", except: [:headers]) do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "Five photos, but post what fits 🔗", crosspost.content
  end

  def test_links_back_with_the_website_card_when_photos_dont_fit
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/five-photos/")

    perfect_vcr_match("bsky_media_link_back", time: "2026-10-22T11:45:00Z", except: [:headers]) do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "Five photos is one too many for some platforms", crosspost.content
  end

  def test_fails_without_posting_when_photos_dont_fit_and_fallback_is_fail
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/five-photos-fail/")

    perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }

    assert_equal "failed", crosspost.reload.status
    assert_equal "Can only attach 4 of this post's 5 media items, and media_fallback is \"fail\"", crosspost.failures.last["cause"]
  end

  private

  def wip_crosspost_for(remote_id)
    Post.find_by(remote_id:).crossposts.first.tap { |crosspost| crosspost.update!(status: "wip") }
  end
end
