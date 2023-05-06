class AddAddressToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :address, :string
  end
end
