module Patterns
  # FYI: hashtags on bsky are limited to 64 chars but that's ridiculous enough that i'm not going to impose it across the board (not knowing what others do)
  HASHTAG = /\B#\p{L}[\p{L}\p{M}\p{Nd}_]*/

  # TLD identifier based on top 200 https://dnsinstitute.com/research/popular-tld-rank/
  # Sorted in descending length b/c the greedy match will find the first one, which can screw up cases like "de" matching a url like "foo.dev/bar" as "foo.de"
  ACCEPTED_TLDS = %w[
    com net ru org info in ir uk au dev de ua ca tr co jp vn cn gr fr tk tw id br io xyz it nl pl za us eu mx ch biz me il es online by xn--p1ai nz kr cz ro cf ar club my tv kz cl pk pro site th se sg cc be rs top ga ma hu ae su dk hk at ml shop store ng np no app live pe ph ie lk gq edu fi ai sa pw tech bd sk ke pt az space mk ge tn lt to gov md asia lv uz hr mn website am ws life fun news mobi vip ee bg la ec blog cloud si work uy link nu ba agency icu media im digital do bz kg is world al ug design xxx cm mu one today so sh tj name network gg ac guru best studio eg fm ms cx sc ve global dz sx vc group qa nf cat py win ki ps buzz gt finance academy host ly bo travel company art tz zw center jo cr ltd click nyc solutions lu tokyo rocks team cy games coop aero market cyou video ci gle zip
  ].sort_by { |tld| -tld.length }

  # Ripped outta this https://github.com/amogil/url_regex/blob/master/lib/url_regex.rb
  URL_PATTERN_STRING = '
    # do not start in the middle of an email/word token
    (?<![A-Za-z0-9._%+-@])
    # scheme
    (?:(?:https?|ftp)://)?
    # NOTE: Do not allow userinfo (user:pass@host) here, because that would
    # cause bare emails like jerry@example.com to be matched as URLs when the
    # scheme is omitted. If we ever need userinfo, we can reintroduce it with
    # a requirement that a scheme be present.

    (?:
      # IP address exclusion
      # private & local networks
      (?!(?:10|127)(?:\.\d{1,3}){3})
      (?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})
      (?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})
      # IP address dotted notation octets
      # excludes loopback network 0.0.0.0
      # excludes reserved space >= 224.0.0.0
      # excludes network & broadcast addresses
      # (first & last IP address of each class)
      (?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])
      (?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}
      (?:\.(?:[0-9]\d?|1\d\d|2[0-4]\d|25[0-5]))
      |
      # host name
      (?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)
      # domain name
      (?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*
      (?:\.(?:' + ACCEPTED_TLDS.join("|") + '))
      # TLD may end with dot
      \.?
    )

    # port number
    (?::\d{2,5})?

    # resource path
    (?:[/?#][^)\]}\?!\.,"\'\s]+(?:[)\]}\?!\.,"\']*[^)\]}\?!\.,"\'\s]+)*)?
  '.freeze
  URL = /#{URL_PATTERN_STRING}/xi

  FEED_NAMESPACE = /\A.*?<feed\b(?=[^>]*\bxmlns(?::(?<ns_suffix>[^=\s]+))?\s*=\s*(?:(?:"https:\/\/posseparty\.com\/2024\/Feed")|(?:'https:\/\/posseparty\.com\/2024\/Feed')))[^>]*>/m
  FEED_POSSE_NAMESPACE = /\A.*?<feed\b(?=[^>]*\bxmlns:posse\s*=\s*(?:"[^"]*"|'[^']*'))[^>]*>/m
end
