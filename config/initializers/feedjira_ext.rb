# See: https://github.com/feedjira/feedjira?tab=readme-ov-file#adding-attributes-to-only-one-class

require "feedjira"

class Feedjira::Parser::AtomEntry
  element :subtitle, as: :subtitle, with: {type: "text"}
  element :subtitle, as: :subtitle, with: {type: nil}
  element :email, as: :author_email

  elements :link, as: :link_rels, value: :rel

  element :"posse:post", as: :syndication_config
end

Feedjira.configure do |config|
  config.strip_whitespace = true
end
