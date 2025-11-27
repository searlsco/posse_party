class FetchesFeed
  class AsksIfAnythingChanged
    def ask(relation, &blk)
      before = relation.maximum(:updated_at)
      blk.call
      relation.maximum(:updated_at) != before
    end
  end
end
