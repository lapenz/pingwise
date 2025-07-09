class AddDnsHostnameToEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :endpoints, :dns_hostname, :string
  end
end
