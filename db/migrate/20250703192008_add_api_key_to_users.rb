class AddApiKeyToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :api_key, :string

    # Generate API keys for existing users
    user_class = Class.new(ActiveRecord::Base) do
      self.table_name = "users"
    end

    user_class.reset_column_information
    user_class.find_each do |user|
      user.update!(api_key: SecureRandom.hex(32))
    end

    change_column_null :users, :api_key, false
    add_index :users, :api_key, unique: true
  end

  def down
    remove_index :users, :api_key
    remove_column :users, :api_key
  end
end
