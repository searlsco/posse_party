# This class depends on agreement with how posse:post is configured as an element in:
# config/initializers/feedjira_ext.rb
class FetchesFeed
  class ParsesFeed
    DEFAULT_POSSE_ELEMENT_NAME = "posse:post"
    OG_TOP_LEVEL_ELEMENTS = ::Feedjira::Parser::AtomEntry.sax_config.top_level_elements.dup.freeze
    MUTEX = Mutex.new

    def parse(response_body)
      post_element = post_element_name(response_body)
      if post_element == DEFAULT_POSSE_ELEMENT_NAME
        Feedjira.parse(response_body)
      else
        MUTEX.synchronize do
          change_posse_element_name!(post_element)
          Feedjira.parse(response_body).tap do
            restore_top_level_elements!
          end
        end
      end
    end

    private

    def post_element_name(xml)
      if (matches = Patterns::FEED_NAMESPACE.match(xml)).present?
        [matches[:ns_suffix], "post"].compact.join(":")
      elsif Patterns::FEED_POSSE_NAMESPACE.match?(xml)
        # This means _something else_ is using the posse namespace
        nil
      else
        DEFAULT_POSSE_ELEMENT_NAME
      end
    end

    def change_posse_element_name!(post_element_name)
      Feedjira::Parser::AtomEntry.sax_config.top_level_elements.delete(DEFAULT_POSSE_ELEMENT_NAME)
      if post_element_name.present?
        Feedjira::Parser::AtomEntry.element post_element_name, as: :syndication_config
      end
    end

    def restore_top_level_elements!
      Feedjira::Parser::AtomEntry.sax_config.top_level_elements = OG_TOP_LEVEL_ELEMENTS.dup
    end
  end
end
