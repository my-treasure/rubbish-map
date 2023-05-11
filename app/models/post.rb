class Post < ApplicationRecord
  belongs_to :user
  has_many :likes, dependent: :destroy
  geocoded_by :address
  after_validation :geocode, if: :will_save_change_to_address?
  has_one_attached :post_image

end
