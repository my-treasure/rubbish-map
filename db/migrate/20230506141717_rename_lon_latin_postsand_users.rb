class RenameLonLatinPostsandUsers < ActiveRecord::Migration[7.0]
  def change
    rename_column :posts, :lng, :longitude
    rename_column :posts, :lat, :latitude
    rename_column :users, :lng, :longitude
    rename_column :users, :lat, :latitude
  end
end
