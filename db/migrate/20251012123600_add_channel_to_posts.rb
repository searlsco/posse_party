class AddChannelToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :channel, :string
  end
end
