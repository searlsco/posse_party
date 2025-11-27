class CreateWaitlisters < ActiveRecord::Migration[8.0]
  def change
    create_table :waitlisters do |t|
      t.string :email
      t.timestamps

      t.index :email, unique: true
    end
  end
end
