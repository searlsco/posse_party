class AddAdminToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :admin, :boolean, null: false, default: false

    # Define User class inline to avoid dependency issues
    user_class = Class.new(ActiveRecord::Base) do
      self.table_name = "users"
    end

    # Set the first user as admin
    if (first_user = user_class.first)
      first_user.update!(admin: true)
    end
  end
end
