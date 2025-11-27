module FeedHelpers
  FEED_URL = "http://justin.searls.co/atom.xml"

  def feed_url
    FEED_URL
  end

  def fake_feed_from(user, file_path)
    stub_request(:get, FEED_URL)
      .to_return(body: File.new(file_fixture(file_path)), status: 200)

    user.feeds.create!(url: feed_url, label: "justin.searls.co - test")
  end
end
