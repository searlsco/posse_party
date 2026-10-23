require "test_helper"

class DownloadsMediaTest < ActiveSupport::TestCase
  def setup
    @subject = DownloadsMedia.new
    @item = CrosspostMedia.new(type: "image", url: "http://localhost:8765/photo-1.jpg")
  end

  def test_downloads_source_images_with_a_separate_larger_limit
    perfect_vcr_match("bsky_media_photos", except: [:headers]) do
      download = @subject.download(@item)

      assert_equal file_fixture("media/photo-1.jpg").binread, download.bytes
      assert_operator DownloadsMedia::MAX_IMAGE_BYTES, :>, Platforms::Bsky::UploadsImages::MAX_IMAGE_BYTES
    ensure
      download&.file&.close!
    end
  end

  def test_refuses_an_oversized_source_and_removes_its_tempfile
    tempfiles = Dir.glob(File.join(Dir.tmpdir, "posse_party_media*#{Process.pid}*"))

    perfect_vcr_match("bsky_media_photos", except: [:headers]) do
      error = assert_raises(PublishesCrosspost::UnsupportedMediaError) { @subject.download(@item, max_bytes: 100) }

      assert_equal @item, error.media
      assert_equal tempfiles, Dir.glob(File.join(Dir.tmpdir, "posse_party_media*#{Process.pid}*"))
    end
  end
end
