class DropWaitlisters < ActiveRecord::Migration[8.0]
  def change
    drop_table :waitlisters do |t|
      t.string :email
      t.timestamps null: false

      t.index :email, unique: true
    end
  end
end
