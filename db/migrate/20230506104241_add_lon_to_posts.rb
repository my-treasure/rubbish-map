class AddLonToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :lon, :float
  end
end
