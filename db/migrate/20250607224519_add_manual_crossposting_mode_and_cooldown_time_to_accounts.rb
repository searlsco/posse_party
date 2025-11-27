class AddManualCrosspostingModeAndCooldownTimeToAccounts < ActiveRecord::Migration[8.0]
  def change
    change_table :accounts do |t|
      t.boolean :manually_publish_crossposts, default: false, null: false
      t.integer :crosspost_cooldown, null: false, default: 0
      t.integer :crosspost_min_age, null: false, default: 0
    end
  end
end
