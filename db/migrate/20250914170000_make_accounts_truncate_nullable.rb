class MakeAccountsTruncateNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :accounts, :truncate, true
    change_column_default :accounts, :truncate, from: true, to: nil
  end
end
