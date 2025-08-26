class ChangeColumnDefaultForAccountsSettings < ActiveRecord::Migration[8.0]
  def change
    change_column_default(:accounts, :settings, from: nil, to: {})
  end
end
