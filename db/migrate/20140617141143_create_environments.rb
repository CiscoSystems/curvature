class CreateEnvironments < ActiveRecord::Migration
  def change
    create_table :environments do |t|
      t.string :username
      t.string :password
      t.string :ip

      # reference the user table
      t.references :user, index: true

      t.timestamps
    end
  end
end
