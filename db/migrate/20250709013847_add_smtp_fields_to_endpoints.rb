class AddSmtpFieldsToEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :endpoints, :smtp_host, :string
    add_column :endpoints, :smtp_port, :integer
    add_column :endpoints, :smtp_use_tls, :boolean
  end
end
