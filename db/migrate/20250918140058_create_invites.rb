class CreateInvites < ActiveRecord::Migration[8.0]
  def up
    create_table :invites do |t|
      t.string :email
      t.string :status, null: false, default: "open"
      t.references :invited_by, null: false, foreign_key: {to_table: :users}
      t.references :received_by, foreign_key: {to_table: :users}
      t.string :token, null: false
      t.datetime :accepted_at

      t.timestamps null: false
    end

    add_index :invites, :status
    add_index :invites, :token, unique: true
    add_index :invites, "lower(email)", unique: true, name: "index_invites_on_lower_email_open", where: "status = 'open'"
    add_check_constraint(
      :invites,
      "status IN ('open', 'accepted')",
      name: "invites_status_valid"
    )
    add_check_constraint(
      :invites,
      "(status <> 'open') OR (email IS NOT NULL AND email <> '')",
      name: "open_invites_require_email"
    )
    add_check_constraint(
      :invites,
      "(status <> 'accepted') OR (received_by_id IS NOT NULL)",
      name: "accepted_invites_require_recipient"
    )
    add_check_constraint(
      :invites,
      "(status <> 'accepted') OR (email IS NULL OR email = '')",
      name: "accepted_invites_require_blank_email"
    )
    add_check_constraint(
      :invites,
      "(received_by_id IS NULL) OR (status = 'accepted')",
      name: "received_by_only_for_accepted"
    )
  end

  def down
    drop_table :invites
  end
end
