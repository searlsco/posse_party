class TemporaryAsset < ApplicationRecord
  belongs_to :crosspost

  validates :key, :bytes, :content_type, presence: true
  validates :key, uniqueness: true
  validates :crosspost_id, uniqueness: true
end
