class AddSystemConfiguration < ActiveRecord::Migration[8.0]
  def change
    create_table :system_configurations do |t|
      t.datetime :fake_now
      t.timestamps
    end
  end
end
