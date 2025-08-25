class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name
      t.jsonb :settings
      t.string :slug

      t.timestamps
    end

    add_index :accounts, :settings, using: :gin
    add_index :accounts, :slug, unique: true, where: "slug IS NOT NULL"
  end
end
