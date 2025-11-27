class Account < ApplicationRecord
  belongs_to :user
  has_many :crossposts, dependent: :destroy

  attribute :credentials, :json, default: -> { {} }

  normalizes :credentials, with: ->(value) { value.is_a?(String) ? JSON.parse(value) : value }
  normalizes :format_string, :append_url_spacer, :append_url_label, :og_image, with: ->(v) { v.presence }

  validates :platform_tag, :label, presence: true
  validate :validate_required_credentials

  def platform
    PublishesCrosspost::MatchesPlatformApi.new.match(self)
  end

  def platform_label
    platform.class::LABEL
  rescue
    platform_tag.to_s.titleize
  end

  def notification_label
    base = platform_label
    if user.accounts.where(platform_tag: platform_tag).count > 1
      "#{base} (#{label})"
    else
      base
    end
  end

  def required_credentials
    platform.required_credentials
  end

  def system_credentials
    credentials.keys - required_credentials
  end

  def default_crosspost_options
    platform.default_crosspost_options
  end

  private

  def validate_required_credentials
    validator = ValidatesAccountCredentials.new
    unless (outcome = validator.validate(self)).success?
      errors.add(:base, outcome.message)
    end
  end
end
