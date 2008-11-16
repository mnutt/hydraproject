# == Schema Information
# Schema version: 20081025182003
#
# Table name: ratio_snapshots
#
#  id            :integer(4)      not null, primary key
#  ratio_sync_id :integer(4)
#  user_id       :integer(4)
#  login         :string(255)
#  downloaded    :integer(4)      default(0)
#  uploaded      :integer(4)      default(0)
#  created_at    :datetime
#

class RatioSnapshot < ActiveRecord::Base
  belongs_to :ratio_sync
  belongs_to :user
end
