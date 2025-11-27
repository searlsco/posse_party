require "test_helper"

class DeletesPostTest < ActiveSupport::TestCase
  def setup
    @subject = DeletesPost.new
  end

  def test_deletes_post_when_no_wip_crossposts
    post_record = posts(:admin_post)
    assert_equal 2, post_record.crossposts.count

    outcome = @subject.delete(post_record)

    assert outcome.success?, outcome.message
    assert_nil Post.find_by(id: post_record.id)
    assert_equal 0, Crosspost.where(post_id: post_record.id).count
  end

  def test_does_not_delete_when_any_crosspost_is_wip
    post_record = posts(:admin_post_without_crossposts)
    account = accounts(:admin_bsky_account)
    Crosspost.create!(post: post_record, account: account, status: "wip")

    outcome = @subject.delete(post_record)

    assert outcome.failure?
    assert_match(/crossposts are in progress/i, outcome.message)
    assert Post.find_by(id: post_record.id)
  end
end
