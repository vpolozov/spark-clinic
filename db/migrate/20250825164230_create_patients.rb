class CreatePatients < ActiveRecord::Migration[8.0]
  def change
    create_table :patients, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :external_id
      t.string :name
      t.date :dob

      t.timestamps
    end
    add_index :patients, :external_id
  end
end
