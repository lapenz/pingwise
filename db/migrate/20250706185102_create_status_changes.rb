class CreateStatusChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :status_changes do |t|
      t.references :endpoint, null: false, foreign_key: true
      t.integer :status
      t.decimal :response_time_ms, precision: 10, scale: 2
      t.datetime :checked_at
      t.string :message

      t.timestamps
      t.index :checked_at
    end
  end
end
