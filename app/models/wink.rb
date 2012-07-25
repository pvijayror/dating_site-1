class Wink < ActiveRecord::Base
  attr_accessible :receiver_id
  belongs_to :sender, class_name: 'Profile', foreign_key: 'sender_id'
  belongs_to :receiver, class_name: 'Profile', foreign_key: 'receiver_id'

  validates :sender_id, presence: true
  validates :receiver_id, presence: true
  
  validates_uniqueness_of :receiver_id, scope: :sender_id
end
