class AddLontoUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :lon, :float
  end
end
