class AddTenantToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :tenant, :string
  end
end
