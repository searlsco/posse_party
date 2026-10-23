require "test_helper"

class LinkedinMediaTest < ActiveJob::TestCase
  def setup
    @user = New.create(User, email: "user@example.com")
    @user.accounts.create!(platform_tag: "linkedin", label: "Test Account", credentials: vcr_secrets({
      "client_id" => nil,
      "client_secret" => nil,
      "access_token" => nil,
      "person_urn" => nil
    }))
    FetchesFeed.new.fetch!(fake_feed_from(@user, "2026-10-22-media-attachments.atom.xml"), cache: false)
  end

  def test_attaches_photos_in_place_of_the_article
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/photos/")

    perfect_vcr_match("linkedin_media_photos", except: [:headers]) do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "Two photos for the POSSE Party media test https://posseparty.com/test/media/photos/", crosspost.content
  end

  def test_attaches_a_video_once_processed
    crosspost = wip_crosspost_for("https://posseparty.com/test/media/clip/")

    perfect_vcr_match("linkedin_media_clip", except: [:headers]) do
      perform_enqueued_jobs { PublishesCrosspost.new.publish(crosspost.id) }
    end

    assert_empty crosspost.reload.failures
    assert_equal "published", crosspost.status
    assert_equal "A short clip for the POSSE Party media test https://posseparty.com/test/media/clip/", crosspost.content
  end

  private

  def wip_crosspost_for(remote_id)
    Post.find_by(remote_id:).crossposts.first.tap { |crosspost| crosspost.update!(status: "wip") }
  end
end
