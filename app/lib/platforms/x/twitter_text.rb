require "twitter-text"

class Platforms::X::TwitterText
  class Counter
    include Twitter::TwitterText::Validation

    def call(content)
      parse_tweet(content)[:weighted_length]
    end
  end

  # Adapted from Twitter::TwitterText::Regex[:valid_url], but we don't want to capture each piece, just want to scan them
  # See: https://github.com/twitter/twitter-text/blob/30e2430d90cff3b46393ea54caf511441983c260/rb/lib/twitter-text/regex.rb#L257
  URL_PATTERN = %r{
    (?:#{Twitter::TwitterText::Regex::REGEXEN[:valid_url_preceding_chars]})\K
    (?:
      (?:https?://)?
      #{Twitter::TwitterText::Regex::REGEXEN[:valid_domain]}
      (?::(?:#{Twitter::TwitterText::Regex::REGEXEN[:valid_port_number]}))?
      (?:/#{Twitter::TwitterText::Regex::REGEXEN[:valid_url_path]}*)?
      (?:\?#{Twitter::TwitterText::Regex::REGEXEN[:valid_url_query_chars]}*#{Twitter::TwitterText::Regex::REGEXEN[:valid_url_query_ending_chars]})?
    )
  }iox

  # Adapted from Twitter::TwitterText::Regex[:valid_hashtag], but we don't want to capture each piece, just want to scan them
  # See: https://github.com/twitter/twitter-text/blob/30e2430d90cff3b46393ea54caf511441983c260/rb/lib/twitter-text/regex.rb#L127
  # Generated from unicode_regex/unicode_regex_groups.scala, more inclusive than Ruby's \p{L}\p{M}
  HASHTAG_LETTERS_AND_MARKS = "\\p{L}\\p{M}" \
    "\u037f\u0528-\u052f\u08a0-\u08b2\u08e4-\u08ff\u0978\u0980\u0c00\u0c34\u0c81\u0d01\u0ede\u0edf" \
    "\u10c7\u10cd\u10fd-\u10ff\u16f1-\u16f8\u17b4\u17b5\u191d\u191e\u1ab0-\u1abe\u1bab-\u1bad\u1bba-" \
    "\u1bbf\u1cf3-\u1cf6\u1cf8\u1cf9\u1de7-\u1df5\u2cf2\u2cf3\u2d27\u2d2d\u2d66\u2d67\u9fcc\ua674-" \
    "\ua67b\ua698-\ua69d\ua69f\ua792-\ua79f\ua7aa-\ua7ad\ua7b0\ua7b1\ua7f7-\ua7f9\ua9e0-\ua9ef\ua9fa-" \
    "\ua9fe\uaa7c-\uaa7f\uaae0-\uaaef\uaaf2-\uaaf6\uab30-\uab5a\uab5c-\uab5f\uab64\uab65\uf870-\uf87f" \
    "\uf882\uf884-\uf89f\uf8b8\uf8c1-\uf8d6\ufa2e\ufa2f\ufe27-\ufe2d\u{102e0}\u{1031f}\u{10350}-\u{1037a}" \
    "\u{10500}-\u{10527}\u{10530}-\u{10563}\u{10600}-\u{10736}\u{10740}-\u{10755}\u{10760}-\u{10767}" \
    "\u{10860}-\u{10876}\u{10880}-\u{1089e}\u{10980}-\u{109b7}\u{109be}\u{109bf}\u{10a80}-\u{10a9c}" \
    "\u{10ac0}-\u{10ac7}\u{10ac9}-\u{10ae6}\u{10b80}-\u{10b91}\u{1107f}\u{110d0}-\u{110e8}\u{11100}-" \
    "\u{11134}\u{11150}-\u{11173}\u{11176}\u{11180}-\u{111c4}\u{111da}\u{11200}-\u{11211}\u{11213}-" \
    "\u{11237}\u{112b0}-\u{112ea}\u{11301}-\u{11303}\u{11305}-\u{1130c}\u{1130f}\u{11310}\u{11313}-" \
    "\u{11328}\u{1132a}-\u{11330}\u{11332}\u{11333}\u{11335}-\u{11339}\u{1133c}-\u{11344}\u{11347}" \
    "\u{11348}\u{1134b}-\u{1134d}\u{11357}\u{1135d}-\u{11363}\u{11366}-\u{1136c}\u{11370}-\u{11374}" \
    "\u{11480}-\u{114c5}\u{114c7}\u{11580}-\u{115b5}\u{115b8}-\u{115c0}\u{11600}-\u{11640}\u{11644}" \
    "\u{11680}-\u{116b7}\u{118a0}-\u{118df}\u{118ff}\u{11ac0}-\u{11af8}\u{1236f}-\u{12398}\u{16a40}-" \
    "\u{16a5e}\u{16ad0}-\u{16aed}\u{16af0}-\u{16af4}\u{16b00}-\u{16b36}\u{16b40}-\u{16b43}\u{16b63}-" \
    "\u{16b77}\u{16b7d}-\u{16b8f}\u{16f00}-\u{16f44}\u{16f50}-\u{16f7e}\u{16f8f}-\u{16f9f}\u{1bc00}-" \
    "\u{1bc6a}\u{1bc70}-\u{1bc7c}\u{1bc80}-\u{1bc88}\u{1bc90}-\u{1bc99}\u{1bc9d}\u{1bc9e}\u{1e800}-" \
    "\u{1e8c4}\u{1e8d0}-\u{1e8d6}\u{1ee00}-\u{1ee03}\u{1ee05}-\u{1ee1f}\u{1ee21}\u{1ee22}\u{1ee24}" \
    "\u{1ee27}\u{1ee29}-\u{1ee32}\u{1ee34}-\u{1ee37}\u{1ee39}\u{1ee3b}\u{1ee42}\u{1ee47}\u{1ee49}" \
    "\u{1ee4b}\u{1ee4d}-\u{1ee4f}\u{1ee51}\u{1ee52}\u{1ee54}\u{1ee57}\u{1ee59}\u{1ee5b}\u{1ee5d}\u{1ee5f}" \
    "\u{1ee61}\u{1ee62}\u{1ee64}\u{1ee67}-\u{1ee6a}\u{1ee6c}-\u{1ee72}\u{1ee74}-\u{1ee77}\u{1ee79}-" \
    "\u{1ee7c}\u{1ee7e}\u{1ee80}-\u{1ee89}\u{1ee8b}-\u{1ee9b}\u{1eea1}-\u{1eea3}\u{1eea5}-\u{1eea9}" \
    "\u{1eeab}-\u{1eebb}"

  # Generated from unicode_regex/unicode_regex_groups.scala, more inclusive than Ruby's \p{Nd}
  HASHTAG_NUMERALS = "\\p{Nd}" \
    "\u0de6-\u0def\ua9f0-\ua9f9\u{110f0}-\u{110f9}\u{11136}-\u{1113f}\u{111d0}-\u{111d9}\u{112f0}-" \
    "\u{112f9}\u{114d0}-\u{114d9}\u{11650}-\u{11659}\u{116c0}-\u{116c9}\u{118e0}-\u{118e9}\u{16a60}-" \
    "\u{16a69}\u{16b50}-\u{16b59}"
  HASHTAG_SPECIAL_CHARS = "_\u200c\u200d\ua67e\u05be\u05f3\u05f4\uff5e\u301c\u309b\u309c\u30a0\u30fb\u3003\u0f0b\u0f0c\u00b7"
  HASHTAG_LETTERS_NUMERALS = "#{HASHTAG_LETTERS_AND_MARKS}#{HASHTAG_NUMERALS}#{HASHTAG_SPECIAL_CHARS}"
  HASHTAG_LETTERS_NUMERALS_SET = "[#{HASHTAG_LETTERS_NUMERALS}]"
  HASHTAG_LETTERS_SET = "[#{HASHTAG_LETTERS_AND_MARKS}]"

  # Updated with \K to reset prior captures:
  HASHTAG = /(?:\A|\ufe0e|\ufe0f|[^&#{HASHTAG_LETTERS_NUMERALS}])\K(?:#|＃)(?!\ufe0f|\u20e3)(?:#{HASHTAG_LETTERS_NUMERALS_SET}*#{HASHTAG_LETTERS_SET}#{HASHTAG_LETTERS_NUMERALS_SET}*)/io

  HASHTAG_PATTERN = /#{HASHTAG}/io
end
