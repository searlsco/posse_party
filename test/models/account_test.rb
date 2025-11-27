require "test_helper"

class AccountTest < ActiveSupport::TestCase
  setup do
    @subject = Account.new
  end

  def test_platform_tag_resolves_platform
    @subject.platform_tag = nil
    assert_raises { @subject.platform }

    @subject.platform_tag = "bsky"
    assert_kind_of Platforms::Bsky, @subject.platform
  end
end
