class Invite < ApplicationRecord
  STATUSES = %w[open accepted].freeze

  belongs_to :invited_by, class_name: "User"
  belongs_to :received_by, class_name: "User", optional: true

  scope :open, -> { where(status: "open") }

  normalizes :email, with: ->(email) { email&.strip&.downcase }

  before_validation :ensure_status
  before_validation :ensure_token

  validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}, if: :open?
  validates :email, absence: true, if: :accepted?
  validates :email, uniqueness: {case_sensitive: true, if: :open?}
  validates :status, inclusion: {in: STATUSES}
  validate :email_not_taken_when_open
  validate :received_by_matches_status
  validate :invited_by_must_be_admin

  def open?
    status == "open"
  end

  def accepted?
    status == "accepted"
  end

  def accept!(recipient)
    return unless open?

    update!(
      status: "accepted",
      accepted_at: Time.current,
      received_by: recipient,
      email: nil
    )
  end

  def self.for_email(email)
    where(email: email.to_s.strip.downcase)
  end

  private

  def ensure_status
    self.status ||= "open"
  end

  def ensure_token
    self.token ||= SecureRandom.hex(24)
  end

  def email_not_taken_when_open
    return unless open?
    return if email.blank?

    if User.exists?(email: email.to_s.strip.downcase)
      errors.add(:email, "already belongs to an existing user")
    end
  end

  def received_by_matches_status
    if open? && received_by_id.present?
      errors.add(:received_by, "must be blank while the invite is open")
    elsif accepted? && received_by_id.blank?
      errors.add(:received_by, "must be present when invite is accepted")
    end
  end

  def invited_by_must_be_admin
    return if invited_by&.admin?

    errors.add(:invited_by, "must be an admin")
  end
end
