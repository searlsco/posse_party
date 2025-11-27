require "test_helper"

class PatternsTest < ActiveSupport::TestCase
  AN_URL = "https://gram.betterwithbecky.com/posts/190/2025-01-03-beckygram-in-your-inbox"

  def test_newlines
    s = "justin.searls.co/atom.xml\n\nAFAICT, 90% of XML validators don’t look up referenced XSD URLs and literally zero will validate against all of them if a default namespace is used at all. Prove me wrong"
    assert_equal ["justin.searls.co/atom.xml"], s.scan(Patterns::URL)
  end

  def test_url_edgecases
    assert_match Patterns::URL, AN_URL
    assert_equal ["#{AN_URL}/"], "#{AN_URL}/".scan(Patterns::URL)
    assert_equal [AN_URL], AN_URL.scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}) ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL})\n ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}). ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}]]]] ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}} ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}! ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}? ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}. ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}?! ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}\" ".scan(Patterns::URL)
    assert_equal [AN_URL], "#{AN_URL}' ".scan(Patterns::URL)
    assert_equal ["#{AN_URL})bamf=123"], "#{AN_URL})bamf=123 ".scan(Patterns::URL)
    assert_equal ["#{AN_URL})8"], "#{AN_URL})8 ".scan(Patterns::URL)
    assert_equal ["#{AN_URL}).8"], "#{AN_URL}).8 ".scan(Patterns::URL)
  end

  def test_feed_namespace
    xml = <<~XML
      <feed xmlns="http://www.w3.org/2005/Atom"
        xml:lang="en-us"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:posse="https://posseparty.com/2024/Feed"
        xsi:schemaLocation="
          http://www.w3.org/2005/Atom https://raw.githubusercontent.com/docjason/XmlValidate/refs/heads/master/schemas/atom.xsd
          https://posseparty.com/2024/Feed https://posseparty.com/2024/Feed.xsd">
    XML

    assert (matches = Patterns::FEED_NAMESPACE.match(xml)).present?
    assert_equal "posse", matches[:ns_suffix]

    xml = xml.gsub("xmlns:posse", "xmlns:wtf")
    assert (matches = Patterns::FEED_NAMESPACE.match(xml)).present?
    assert_equal "wtf", matches[:ns_suffix]

    # no suffix but still a match b/c the declaration is there as a top-level
    xml = xml.gsub("xmlns:wtf", "xmlns")
    assert (matches = Patterns::FEED_NAMESPACE.match(xml)).present?
    assert_nil matches[:ns_suffix]

    xml = xml.gsub("posseparty.com", "somebullshit.com")
    assert_nil Patterns::FEED_NAMESPACE.match(xml)
  end
end
