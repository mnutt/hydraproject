class RatioSync < ActiveRecord::Base
  #has_many :ratio_snapshots
  
  def ratio_snapshots
    RatioSnapshot.find(:all, :conditions => ["ratio_sync_id = ?", self.sync_id], :include => :user)
  end
  
  def self.last(domain)
    RatioSync.find(:first, :conditions => ["domain = ?", domain], :order => 'sync_id DESC')
  end
  
  def self.next_id(domain)
    rs = RatioSync.last(domain)
    (rs.nil?) ? nil : (rs.sync_id + 1)
  end
  
end
