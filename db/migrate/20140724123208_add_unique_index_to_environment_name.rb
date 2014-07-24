class AddUniqueIndexToEnvironmentName < ActiveRecord::Migration
  def change
    add_index :environments, :name, unique: true
  end
end
