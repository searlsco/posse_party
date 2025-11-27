class Post < ApplicationRecord
  belongs_to :feed
  has_many :crossposts, dependent: :destroy

  validates :url, :remote_id, presence: true
  validates :remote_id, uniqueness: {scope: :feed_id}

  def notification_label
    t = title.to_s.strip
    if t.present?
      "\"#{t.truncate(60, omission: "…")}\""
    else
      "Post ##{id}"
    end
  end
end
