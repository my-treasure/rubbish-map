class RenameLonColumnToLngInPostsAndUsers < ActiveRecord::Migration[7.0]
  def change
    rename_column :posts, :lon, :lng
    rename_column :users, :lon, :lng
  end
end
