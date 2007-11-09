class RatioSnapshot < ActiveRecord::Base
  belongs_to :ratio_sync
  belongs_to :user
end
