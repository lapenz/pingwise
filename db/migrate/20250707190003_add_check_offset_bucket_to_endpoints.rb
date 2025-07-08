class AddCheckOffsetBucketToEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :endpoints, :check_offset_bucket, :integer
  end
end 