require "test_helper"

class InstagramCaptionReigniteTest < ActiveJob::TestCase
  def setup
    @user = New.create(User)
    @instagram = @user.accounts.find_or_create_by!(platform_tag: "instagram", label: "@testman", credentials: vcr_secrets({
      "app_id" => nil,
      "app_secret" => nil,
      "user_id" => nil,
      "access_token" => nil
    }))
  end

  def test_instagram_caption_for_beckygram_reignite
    feed = fake_feed_from(@user, "2025-11-03-beckygram.atom.xml")
    FetchesFeed.new.fetch!(feed, cache: false)

    post = Post.find_by(remote_id: "https://beckygram.com/posts/1064/2025-11-02-build-with-becky-reignite")
    assert post, "expected the 'Reignite' post to be imported"

    crosspost = Crosspost.includes(:account).find_by!(post_id: post.id, account_id: @instagram.id)

    api = Platforms::Instagram.new
    crosspost_config = PublishesCrosspost::MungesConfig.new.munge(crosspost, api.default_crosspost_options)
    composed = PublishesCrosspost::ComposesCrosspostContent.new.compose(crosspost_config, api.post_constraints)

    expected = <<~CAPTION.strip
      You feeling it? 😅

      Oh yeah — we've officially entered Happy Hallow-Thanks-Mas Eve , a.k.a. Silly Season! 👻🦃🎄🎉

      I love this time of year — it’s special, cozy, and full of connection — but it also comes with its fair share of stress. (https://gram.betterwithbecky.com/posts/1010/2025-10-08-world-mental-health-day-dont-let-the-holidays-haunt-you)
      If you’re already feeling that pull of holiday chaos and craving something to ground you — I’ve got you.

      The next Build with Becky Program is a 5-week “Reignite” phase — designed to bring you back to basics: Squat, Hinge, Push, and Pull patterns (with a special focus on squat and horizontal push/bench press) + Core, Arms, and Glutes finishers, with guided warm-ups and mobility to keep your body feeling its best.

      You’ll get 3 options for every movement , so you can lift anywhere — full gym, limited setup, or just bands/bodyweight if you're on the road visiting family and friends. My app walks you through everything on your phone, laptop, or tablet — no guesswork, no stress.

      You’ll learn exactly how to lift safely and push yourself just enough to build strength without pain, plateaus, or burnout.
      Show up for yourself consistently, and:

      • ✅ After 1 week → you’ll feel better (energy, stress, sleep).
      • ✅ After 3 weeks → you’ll feel stronger and more capable (inside and out)
      • ✅ After 5 → you’ll see how strong you’ve become — the best gift you can give yourself this season. 🎁💪

      Ready to feel grounded and ahead of the pack before the New Year rush?

      🚀 BWB Reignite is available starting Sunday, 11/2 — learn more and sign up at https://www.betterwithbecky.com.

      See the full post at:
      https://beckygram.com/posts/1064/2025-11-02-build-with-becky-reignite
    CAPTION

    assert_equal expected, composed.string
  end
end
