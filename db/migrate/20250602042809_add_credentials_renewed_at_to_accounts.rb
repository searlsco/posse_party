class AddCredentialsRenewedAtToAccounts < ActiveRecord::Migration[8.0]
  def change
    change_table :accounts do |t|
      t.datetime :credentials_renewed_at
    end
  end
end
