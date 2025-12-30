class CreateObservations < ActiveRecord::Migration[7.1]
  def change
    create_table :observations, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :patient, null: false, foreign_key: true, type: :uuid
      t.string :type, null: false # STI

      # FHIR-like common attributes
      t.string :status, default: "final" # e.g., "final", "preliminary", "amended"
      t.string :category # e.g., "vital-signs", "laboratory"
      t.string :code # e.g., "GLU", "BP", "WEIGHT" (or LOINC codes)
      t.string :interpretation # e.g., "normal", "high", "low"
      t.jsonb :reference_range, default: {} # e.g., {"low": 70, "high": 100, "unit": "mg/dL"}
      t.datetime :recorded_at, null: false

      # All observation values stored in a single JSONB column
      t.jsonb :data, default: {}

      t.timestamps
    end

    add_index :observations, :type
    add_index :observations, :code
    add_index :observations, :recorded_at
    add_index :observations, :reference_range, using: :gin
    add_index :observations, :data, using: :gin
  end
end
