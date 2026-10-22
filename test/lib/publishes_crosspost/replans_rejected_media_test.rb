require "test_helper"
require "mocktail"

class PublishesCrosspost::ReplansRejectedMediaTest < ActiveJob::TestCase
  def test_replans_with_the_fallback_when_the_platform_refuses_an_item
    crosspost = posts(:admin_post).crossposts.create!(account: accounts(:admin_x_account), status: "wip")
    crosspost.post.update!(media: [{"type" => "video", "url" => "https://example.com/huge.mp4"}])
    x = Mocktail.of_next(Platforms::X)
    stubs { x.default_crosspost_options }.with { Platforms::X::DEFAULT_CROSSPOST_OPTIONS }
    stubs { x.post_constraints }.with { Platforms::X::POST_CONSTRAINTS }
    stubs { x.supports_channel?("feed") }.with { true }
    stubs { |m| x.media_constraints(m.any) }.with { Platforms::X::MEDIA_CONSTRAINTS }
    stubs { |m| x.publish!(crosspost, m.that { |config| config.media.any? }, m.any) }.with { |call|
      raise PublishesCrosspost::UnsupportedMediaError.new(call.args[1].media.first, "Too big")
    }
    stubs { |m| x.publish!(crosspost, m.that { |config| config.media.empty? }, m.any) }.with { |call|
      call.args[0].update!(status: "published", content: call.args[2].string)
      PublishesCrosspost::Result.new(success?: true)
    }

    PublishesCrosspost.new.publish(crosspost.id)

    assert_equal "published", crosspost.reload.status
    assert_empty crosspost.failures
    assert_equal "Admin's First Post https://admin.example.com/posts/1", crosspost.content
  end

  def test_media_that_fails_processing_later_is_left_out_of_the_next_attempt
    crosspost = posts(:admin_post).crossposts.create!(account: accounts(:admin_x_account), status: "wip", last_attempted_at: Now.time)
    crosspost.post.update!(media: [{"type" => "video", "url" => "https://example.com/broken.mp4"}])
    x = Mocktail.of_next(Platforms::X)
    stubs { x.finishable? }.with { true }
    stubs { x.finish!(crosspost) }.with { raise PublishesCrosspost::UnsupportedMediaError.new(CrosspostMedia.new(url: "https://example.com/broken.mp4"), "X failed to process it") }

    PublishesCrosspost::FinishesCrosspost.new.publish(crosspost.id)

    assert_equal ["https://example.com/broken.mp4"], crosspost.reload.metadata["rejected_media_urls"]
    assert_equal "X failed to process it. Publishing again without it", crosspost.failures.last["message"]
    assert_enqueued_with(job: PublishCrosspostJob, args: [crosspost.id])
    assert_empty ComposesCrosspostPreview.new.media(crosspost)
  end
end
