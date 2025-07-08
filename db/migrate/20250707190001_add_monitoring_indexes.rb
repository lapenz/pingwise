class AddMonitoringIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :endpoints, [:enabled, :last_checked_at]
    add_index :status_changes, [:endpoint_id, :checked_at]
  end
end