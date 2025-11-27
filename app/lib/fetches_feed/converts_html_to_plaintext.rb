class FetchesFeed
  class ConvertsHtmlToPlaintext
    def initialize
      @strips_markdown = StripsMarkdown.new
    end

    def convert(html)
      return html if html.blank?

      text = @strips_markdown.strip(
        ReverseMarkdown.convert(preprocess_html(html)).strip
      ).strip

      # Normalize: cap runs of >2 newlines to exactly 2
      text.gsub(/\n{3,}/, "\n\n")
    end

    private

    def preprocess_html(html)
      # Convert literal newlines that are inside text nodes into <br/>
      # without touching tag/attribute boundaries. Use Nokogiri to walk text nodes.
      fragment = Nokogiri::HTML::DocumentFragment.parse(html)

      # Drop non-text media/embed elements entirely (DOM-based, not regex)
      fragment.css("video,audio,picture,figure,img,source,track,iframe,embed,svg,canvas,object").remove
      fragment.xpath(".//text()").each do |text_node|
        content = text_node.content
        next unless content.include?("\n")

        # If this text node is only whitespace, collapse all whitespace to a single space
        if content.strip.empty?
          text_node.content = " "
          next
        end

        parts = content.split("\n", -1)
        new_nodes = []
        parts.each_with_index do |part, idx|
          new_nodes << Nokogiri::XML::Text.new(part, text_node.document) unless part.empty?

          # For each newline between parts (i.e., not after the last part)
          next unless idx < parts.length - 1

          # If the newline is at the very end of this text node (next part empty),
          # prefer a single space to avoid creating a hard line break before the next element.
          new_nodes << if idx == parts.length - 2 && parts.last == ""
            Nokogiri::XML::Text.new(" ", text_node.document)
          else
            Nokogiri::XML::Node.new("br", text_node.document)
          end
        end

        if new_nodes.empty?
          text_node.content = " "
        else
          new_nodes.each { |n| text_node.add_previous_sibling(n) }
          text_node.remove
        end
      end

      fragment.to_html
    end
  end
end
