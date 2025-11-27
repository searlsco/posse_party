class User < ApplicationRecord
  has_many :accounts, dependent: :destroy
  has_many :feeds, dependent: :destroy
  has_many :posts, through: :feeds
  has_many :crossposts, through: :feeds
  has_many :notifications, dependent: :delete_all
  has_many :sent_invites, class_name: "Invite", foreign_key: :invited_by_id, dependent: :destroy
  has_one :received_invitation, class_name: "Invite", foreign_key: :received_by_id, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :api_key, presence: true, uniqueness: true
  normalizes :email, with: ->(email) { email.strip.downcase }
  has_secure_password
  generates_token_for :email_auth, expires_in: 30.minutes
  generates_token_for :password_reset, expires_in: 30.minutes

  after_create :link_received_invite
  validate :cannot_demote_with_active_invites, if: :will_save_change_to_admin?

  def admin?
    admin
  end

  private

  def link_received_invite
    invite = Invite.open.for_email(email).first
    return if invite.blank?

    invite.accept!(self)
  end

  def cannot_demote_with_active_invites
    return if admin?
    return unless sent_invites.open.exists?

    errors.add(:admin, "cannot be revoked while invites are outstanding")
  end
end
