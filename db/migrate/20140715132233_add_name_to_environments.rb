class AddNameToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :name, :string
  end
end
