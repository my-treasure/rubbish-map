class Post < ApplicationRecord
  belongs_to :user
  geocoded_by :address
  after_validation :geocode, if: :will_save_change_to_address?
  #mount_uploader :post_image, PostImageUploader
  # gem carrierwave

end
