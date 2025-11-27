require "test_helper"

class AsksIfAnythingChangedTest < ActiveSupport::TestCase
  setup do
    @post = New.create(Post)
    @subject = FetchesFeed::AsksIfAnythingChanged.new
  end

  def test_nothing_changed
    @post.update!(title: "old title")
    refute @subject.ask(Post.all) {
      @post.update!(title: "old title") # won't save b/c same
    }
  end

  def test_something_changed
    assert @subject.ask(Post.all) {
      @post.update!(title: "new title")
    }
  end
end
