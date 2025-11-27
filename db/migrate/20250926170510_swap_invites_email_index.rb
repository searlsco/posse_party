class SwapInvitesEmailIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :invites, :email,
      unique: true,
      name: "index_invites_on_email_open",
      where: "status = 'open'",
      algorithm: :concurrently

    remove_index :invites,
      name: "index_invites_on_lower_email_open",
      algorithm: :concurrently
  end

  def down
    add_index :invites, "lower(email)",
      unique: true,
      name: "index_invites_on_lower_email_open",
      where: "status = 'open'"

    remove_index :invites, name: "index_invites_on_email_open"
  end
end
