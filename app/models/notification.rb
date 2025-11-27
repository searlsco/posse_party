class Notification < ApplicationRecord
  SEVERITIES = %w[info warn success danger].freeze

  belongs_to :user

  validates :title, presence: true
  validates :severity, presence: true, inclusion: {in: SEVERITIES}
  validates :text, presence: true

  def self.search(q)
    return all if q.blank?
    where("search @@ plainto_tsquery('simple', ?)", q)
  end
end
