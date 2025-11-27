require "test_helper"

class FetchesFeed
  class ConvertsHtmlToPlaintextTest < ActiveSupport::TestCase
    setup do
      @subject = ConvertsHtmlToPlaintext.new
    end

    def test_trims_output
      html = <<~HTML
        <p>  hello world  </p>
      HTML

      assert_equal "hello world", @subject.convert(html)
    end

    def test_links_with_urls_as_content_should_simply_be_stripped
      html = <<~HTML
        <p>I was extremely skeptical about GM dumping CarPlay and hiring Baris Cetinok from Apple, and after listening to this interview I am almost certain it was a mistake. Dude can barely string together several concepts in a row in comprehensible English. Can't imagine him running a complex software organization <a href="https://www.theVerge.com/24285581/gm-software-baris-cetinok-apple-carplay-android-auto-google-cars-evs-decoder-podcast" class="inline-block align-bottom max-w-[calc(100%-124px)] text-ellipsis whitespace-nowrap overflow-hidden" >theverge.com/24285581/gm-software-baris-cetinok-apple-carplay-android-auto-google-cars-evs-decoder-podcast</a></p>
      HTML

      assert_equal "I was extremely skeptical about GM dumping CarPlay and hiring Baris Cetinok from Apple, and after listening to this interview I am almost certain it was a mistake. Dude can barely string together several concepts in a row in comprehensible English. Can't imagine him running a complex software organization https://www.theVerge.com/24285581/gm-software-baris-cetinok-apple-carplay-android-auto-google-cars-evs-decoder-podcast", @subject.convert(html)
    end

    def test_mailto
      assert_equal "email me justin@searls.co", @subject.convert("<p>email me <a href='mailto:justin@searls.co'>justin@searls.co</a></p>")
      assert_equal "email us justin@searls.co and jeremy@searls.co", @subject.convert("<p>email us <a href='mailto:justin@searls.co,jeremy@searls.co?poop=butt'>justin@searls.co and jeremy@searls.co</a></p>")
      assert_equal "just email me (justin@searls.co)", @subject.convert("<p>just <a href='mailto:justin@searls.co?subject=lol'>email me</a></p>")
      assert_equal "garbage email me (mailto:?wat)", @subject.convert("<p>garbage <a href='mailto:?wat'>email me</a></p>")
    end

    def test_ol
      html = <<~HTML
        <p>Well, this is a terrible workflow that Apple steers people through when replacing a damaged phone:</p>
          <ol>
            <li>Apple Support app tells you to disable Find My before sending an Express Replacement iPhone</li>
            <li>You receive phone and set it up with Direct Transfer from damaged phone</li>
            <li>You realize a week later that replacement phone has Find My (and Activation Lock) disabled because it copied the setting from the damaged phone.</li>
          </ol>
        <p>Seems bad.</p>
      HTML

      expected = <<~TEXT
        Well, this is a terrible workflow that Apple steers people through when replacing a damaged phone:

        1. Apple Support app tells you to disable Find My before sending an Express Replacement iPhone
        2. You receive phone and set it up with Direct Transfer from damaged phone
        3. You realize a week later that replacement phone has Find My (and Activation Lock) disabled because it copied the setting from the damaged phone.

        Seems bad.
      TEXT

      assert_equal expected.strip, @subject.convert(html)
    end

    def test_ul
      html = <<~HTML
        <p>An list</p>
          <ul>
            <li>Thing</li>
            <li>Thang</li>
          </ul>
        <p>Fin.</p>
      HTML

      expected = <<~TEXT
        An list

        • Thing
        • Thang

        Fin.
      TEXT

      assert_equal expected.strip, @subject.convert(html)
    end

    def test_link_whitespace
      html = <<~HTML
        <p>Test Double is running a survey to better understand YOUR HOTTEST TAKES about software development. Please fill this out as accurately and spicily as possible 🌶️ <a href="https://forms.gle/UcnjShcTUxPVJmTm6" class="inline-block align-bottom max-w-[calc(100%-124px)] text-ellipsis whitespace-nowrap overflow-hidden" >forms.gle/UcnjShcTUxPVJmTm6</a></p>
      HTML
      expected = <<~TEXT
        Test Double is running a survey to better understand YOUR HOTTEST TAKES about software development. Please fill this out as accurately and spicily as possible 🌶️ https://forms.gle/UcnjShcTUxPVJmTm6
      TEXT

      assert_equal expected.strip, @subject.convert(html)
    end

    def test_link_whitespace_harder
      html = <<~HTML
        <p>There's the headline. You know it's real when they pull out the pics of floor traders touching their faces.
        <a href="https://www.theguardian.com/us-news/2025/apr/03/trump-tariffs-stock-market" class="inline-block align-bottom max-w-[calc(100%-124px)] text-ellipsis whitespace-nowrap overflow-hidden" >theguardian.com/us-news/2025/apr/03/trump-tariffs-stock-market</a></p>
      HTML
      expected = <<~TEXT
        There's the headline. You know it's real when they pull out the pics of floor traders touching their faces. https://www.theguardian.com/us-news/2025/apr/03/trump-tariffs-stock-market
      TEXT

      assert_equal expected.strip, @subject.convert(html)
    end

    def test_link_whitespace_even_harder
      html = <<~HTML
        <p>There's the headline. You know it's real when they pull out the pics of floor traders touching their faces.
        <span>my dude</span></p>
      HTML
      expected = <<~TEXT
        There's the headline. You know it's real when they pull out the pics of floor traders touching their faces. my dude
      TEXT

      assert_equal expected.strip, @subject.convert(html)
    end

    def test_literal_newlines_in_html_content_converted_to_newlines
      html = "<p>2008: Social Network\n2014: Social Media\n2025: Content Platform</p>"

      expected = "2008: Social Network\n2014: Social Media\n2025: Content Platform"

      assert_equal expected, @subject.convert(html)
    end

    def test_br_tags_converted_to_newlines
      html = "<p>2008: Social Network<br/>2014: Social Media<br/>2025: Content Platform</p>"

      expected = "2008: Social Network\n2014: Social Media\n2025: Content Platform"

      assert_equal expected, @subject.convert(html)
    end
  end
end
