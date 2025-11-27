class SystemConfiguration < ApplicationRecord
  before_create :ensure_only_one_row

  def self.instance
    @instance ||= find_or_create_by!(id: 1)
  end

  private

  def ensure_only_one_row
    throw :abort if SystemConfiguration.exists?
  end
end
