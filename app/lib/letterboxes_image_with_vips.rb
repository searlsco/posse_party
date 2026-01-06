class LetterboxesImageWithVips
  DEFAULT_TARGET_WIDTH = 2160
  DEFAULT_TARGET_HEIGHT = 3840

  def letterbox(image_bytes, target_width: DEFAULT_TARGET_WIDTH, target_height: DEFAULT_TARGET_HEIGHT)
    require "vips"

    source_image = Vips::Image.new_from_buffer(image_bytes, "")
      .autorot
      .colourspace("srgb")

    source_image = source_image.extract_band(0, n: 3) if source_image.bands > 3

    output_width = [target_width, source_image.width].min
    output_height = (output_width * target_height.fdiv(target_width)).round

    resized_image = source_image.resize([
      output_width.fdiv(source_image.width),
      output_height.fdiv(source_image.height)
    ].min)

    Vips::Image.black(output_width, output_height, bands: 3)
      .insert(
        resized_image,
        (output_width - resized_image.width) / 2,
        (output_height - resized_image.height) / 2
      )
      .write_to_buffer(".jpg", Q: 92, strip: true)
  end
end
