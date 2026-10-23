class PreparesImageUpload
  Image = Struct.new(:bytes, :content_type, :width, :height, keyword_init: true)

  JPEG_QUALITIES = [90, 80, 70, 60].freeze

  # Returns the image as-is when the platform accepts it, otherwise re-encodes it as a
  # JPEG (shrinking it as needed) so it fits within max_bytes. An image that can't be
  # read or shrunk is media the platform can't attach
  def prepare(item, bytes, content_type, max_bytes:, accepted_types: %w[image/jpeg image/png image/webp image/gif])
    require "vips"

    # Dimensions as displayed, which for rotated photos (per their EXIF orientation) aren't as stored
    image = Vips::Image.new_from_buffer(bytes, "").autorot
    if bytes.bytesize <= max_bytes && accepted_types.include?(content_type)
      Image.new(bytes:, content_type:, width: image.width, height: image.height)
    else
      shrink(item, image.colourspace("srgb").then { |i| (i.bands > 3) ? i.flatten(background: 255) : i }, max_bytes)
    end
  rescue Vips::Error => e
    raise PublishesCrosspost::UnsupportedMediaError.new(item, "Couldn't read image #{item.url}: #{e.message.strip}")
  end

  private

  def shrink(item, image, max_bytes, scale: 1.0)
    scaled = (scale < 1.0) ? image.resize(scale) : image
    jpeg = JPEG_QUALITIES.lazy
      .map { |quality| scaled.write_to_buffer(".jpg", Q: quality, strip: true) }
      .find { |candidate| candidate.bytesize <= max_bytes }

    if jpeg
      Image.new(bytes: jpeg, content_type: "image/jpeg", width: scaled.width, height: scaled.height)
    elsif scaled.width > 256
      shrink(item, image, max_bytes, scale: scale * 0.75)
    else
      raise PublishesCrosspost::UnsupportedMediaError.new(item, "Couldn't shrink image #{item.url} below #{ActiveSupport::NumberHelper.number_to_human_size(max_bytes)}")
    end
  end
end
