class RenameAttachOgCardToAttachLink < ActiveRecord::Migration[8.0]
  def change
    rename_column :posts, :attach_og_card, :attach_link
    rename_column :accounts, :attach_og_card, :attach_link
  end
end
