class Feed < ApplicationRecord
  belongs_to :user
  has_many :posts, dependent: :destroy
  has_many :crossposts, through: :posts

  validates :label, :url, presence: true
  validates :url,
    format: {
      with: URI::RFC2396_PARSER.make_regexp(%w[http https]),
      message: "must be a valid URL"
    }

  def notification_label = label
end
