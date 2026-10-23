require "test_helper"
require "vips"

class PreparesImageUploadTest < ActiveSupport::TestCase
  def setup
    @subject = PreparesImageUpload.new
    @item = CrosspostMedia.new(type: "image", url: "https://example.com/photo.jpg")
  end

  def test_passes_through_images_the_platform_accepts
    bytes = file_fixture("media/photo-1.jpg").binread

    image = @subject.prepare(@item, bytes, "image/jpeg", max_bytes: 1.megabyte)

    assert_same bytes, image.bytes
    assert_equal ["image/jpeg", 800, 600], [image.content_type, image.width, image.height]
  end

  def test_shrinks_images_that_are_too_large
    bytes = Vips::Image.gaussnoise(1600, 1200).cast(:uchar).bandjoin([Vips::Image.gaussnoise(1600, 1200).cast(:uchar), Vips::Image.gaussnoise(1600, 1200).cast(:uchar)]).write_to_buffer(".png")

    image = @subject.prepare(@item, bytes, "image/png", max_bytes: 300.kilobytes)

    assert_operator image.bytes.bytesize, :<=, 300.kilobytes
    assert_equal "image/jpeg", image.content_type
    assert_in_delta 4.fdiv(3), image.width.fdiv(image.height), 0.01
  end

  def test_converts_formats_the_platform_does_not_accept
    image = @subject.prepare(@item, file_fixture("3_by_4_photo.webp").binread, "image/webp", max_bytes: 10.megabytes, accepted_types: %w[image/jpeg image/png])

    assert_equal "image/jpeg", image.content_type
    assert_equal "image/jpeg", Marcel::MimeType.for(image.bytes)
  end

  def test_reports_dimensions_as_displayed_for_rotated_photos
    bytes = Vips::Image.black(400, 200).copy.tap { |image| image.set_type(GObject::GINT_TYPE, "orientation", 6) }.write_to_buffer(".jpg")

    image = @subject.prepare(@item, bytes, "image/jpeg", max_bytes: 1.megabyte)

    assert_equal [200, 400], [image.width, image.height]
  end

  def test_unreadable_images_are_media_the_platform_cant_attach
    error = assert_raises(PublishesCrosspost::UnsupportedMediaError) {
      @subject.prepare(@item, "<svg>not really</svg>", "image/svg+xml", max_bytes: 1.megabyte)
    }

    assert_equal @item, error.media
  end
end
