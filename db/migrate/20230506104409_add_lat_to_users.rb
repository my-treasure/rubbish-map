class AddLatToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :lat, :float
  end
end
