class Crosspost < ApplicationRecord
  belongs_to :post, touch: true, strict_loading: false
  belongs_to :account
  has_one :user, through: :account
  has_one :feed, through: :post
  has_one :temporary_asset, dependent: :destroy

  validates :post_id, uniqueness: {scope: :account_id}
  validates :status, inclusion: {in: %w[ready skipped wip published failed]}, presence: true

  def ready?
    status == "ready"
  end

  def wip?
    status == "wip"
  end

  def skipped?
    status == "skipped"
  end

  def published?
    status == "published"
  end

  def failed?
    status == "failed"
  end

  def notification_label
    account.notification_label
  end
end
