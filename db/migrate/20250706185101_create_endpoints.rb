class CreateEndpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :endpoints do |t|
      t.string :name
      t.integer :endpoint_type
      t.string :url
      t.string :ip
      t.integer :port
      t.integer :status
      t.boolean :enabled
      t.references :user, null: false, foreign_key: true
      t.datetime :last_checked_at
      t.integer :check_interval_seconds

      t.timestamps
    end
  end
end
