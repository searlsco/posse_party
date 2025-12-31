require "test_helper"
require "vips"

class LetterboxesImageWithVipsTest < ActiveSupport::TestCase
  def test_letterboxes_landscape_image_into_9_16_without_upscaling
    source_image = Vips::Image.black(1024, 512, bands: 3)
      .new_from_image([255, 0, 0])

    jpeg_bytes = LetterboxesImageWithVips.new.letterbox(source_image.write_to_buffer(".png"))
    output_image = Vips::Image.new_from_buffer(jpeg_bytes, "")
    top_center_pixel = output_image.getpoint(512, 0)
    center_pixel = output_image.getpoint(512, 910)

    assert_equal 1024, output_image.width
    assert_equal 1820, output_image.height
    assert_equal [0.0, 0.0, 0.0], top_center_pixel
    assert_operator center_pixel[0], :>, 250
    assert_equal 0.0, center_pixel[1]
    assert_equal 0.0, center_pixel[2]
  end

  def test_scales_down_to_a_max_width_of_2160
    source_image = Vips::Image.black(3000, 1500, bands: 3)
      .new_from_image([255, 0, 0])

    jpeg_bytes = LetterboxesImageWithVips.new.letterbox(source_image.write_to_buffer(".png"))
    output_image = Vips::Image.new_from_buffer(jpeg_bytes, "")

    assert_equal 2160, output_image.width
    assert_equal 3840, output_image.height
    assert_equal [0.0, 0.0, 0.0], output_image.getpoint(1080, 0)
    assert_operator output_image.getpoint(1080, 1920)[0], :>, 250
  end
end
