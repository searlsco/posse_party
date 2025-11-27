require "test_helper"

class Notifications::PreloadsRefsTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "t@example.com",
      api_key: SecureRandom.hex(16),
      password: "Password!1",
      password_confirmation: "Password!1"
    )
    @feed = Feed.create!(user: @user, label: "F", url: "https://x.example/feed")
    @post = Post.create!(feed: @feed, url: "u", remote_id: "r1")
    @account = Account.create!(user: @user, platform_tag: "test", label: "A", credentials: {})
    @crosspost = Crosspost.create!(post: @post, account: @account, status: "ready")
    @subject = Notifications::PreloadsRefs.new
  end

  test "preloads grouped refs into id-indexed hashes" do
    refs = [
      {"model" => "Post", "id" => @post.id},
      {"model" => "Crosspost", "id" => @crosspost.id},
      {"model" => "Account", "id" => @account.id}
    ]
    loaded = @subject.preload(refs)
    assert_equal @post, loaded.dig("Post", @post.id)
    assert_equal @crosspost, loaded.dig("Crosspost", @crosspost.id)
    assert_equal @account, loaded.dig("Account", @account.id)
  end

  test "ignores unknown models and malformed refs" do
    refs = [
      {"model" => "Nope", "id" => 1},
      {"model" => "User", "id" => @user.id},
      {},
      nil,
      {"url" => "https://example.com"}
    ]
    loaded = @subject.preload(refs)
    assert_equal({}, loaded)
  end
end
