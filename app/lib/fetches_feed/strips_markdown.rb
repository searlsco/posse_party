require "redcarpet/render_strip"

class FetchesFeed
  class StripsMarkdown
    def initialize
      @renderer = Redcarpet::Markdown.new(MarkdownStripper.new)
    end

    def strip(markdown)
      @renderer.render(markdown)
    end

    class MarkdownStripper < Redcarpet::Render::StripDown
      def initialize
        super
        @list_ordinal = 0
      end

      def paragraph(text)
        text + "\n\n"
      end

      def header(text, header_level)
        ("#" * header_level) + " " + text + "\n\n"
      end

      def link(link, title, content)
        link = link.to_s.strip
        normalized_link = link.downcase.sub(/^https?:\/\//, "")
        normalized_content = content.to_s.downcase.strip

        if normalized_link.start_with?("mailto:")
          if (email_address_matches = normalized_link.match(/mailto:([^?]+)/))
            if (email_addresses = email_address_matches[1].split(",")).all? { |email| normalized_content.include?(email) }
              content
            else
              "#{content} (#{email_addresses.join(", ")})"
            end
          else
            "#{content} (#{link})"
          end
        elsif normalized_link == normalized_content || content.to_s.match?(Patterns::URL)
          link
        else
          content.to_s.blank? ? link : "#{content} (#{link})"
        end
      end

      # This whole scheme for ordered lists will fall down on nested ordered lists so don't write those?
      def list(content, list_type)
        if list_type == :ordered
          @list_ordinal = 0
        end
        "#{content}\n"
      end

      def list_item(content, list_type)
        if list_type == :ordered
          @list_ordinal += 1
          "#{@list_ordinal}. #{content}"
        else
          "• #{content}"
        end
      end

      def linebreak
        "\n"
      end
    end
  end
end
