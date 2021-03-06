class Profile < ActiveRecord::Base
  attr_accessible :interested_in, :about_me, :age, :good_at, :location, :message_me_if, 
  	:relationship_status, :sex, :body_type, :height, :ethnicity, :smokes,
  	:drinks, :religion, :income, :job, :language, :drugs, :offspring, :exercise, :zipcode,
    :formatted_height, :avatar, :nick_name, :photos_attributes
  INTERESTED_TYPES= [ "Male", "Female", "Both" ]  
  RELATIONSHIP_TYPES = [ "Single", "Available", "Separated", "Divorced",
  		"Widower", "Married", "In a relationship" ]
  BODY_TYPES = [ "No Answer", "Used Up", "Athletic and Toned", "Skinny", 
  		"Slender", "Fat"  ]		
  RELIGION_TYPES = [ "No Answer", "Christianity", "Atheism", "Agnostic", "Spiritual but not Religious",
  		"Judaism", "Buddhist", "Other" ]
  INCOME_TYPES = [ "No Answer", "Less than $25,000", "$25000-50000", "$50000-100000", "$100000-250000",
  		"Over $250000" ]
  LANGUAGE_TYPES = [ "No Answer", "English", "German", "Spanish", "C++", "French", "Chinese" ]
  EXERCISE_TYPES = [ "No Answer", "Never", "Rarely", "1-2 times/week", "3-4 times/week", "5+ times/week"]
  DRINKS_TYPES = [ "No Answer", "Heavily", "Moderately", "Socially", "Occasionally",
  		"Never", "Very very rarely" ]
  DRUGS_TYPES = [ "No Answer", "Sometimes", "Never", "Frequently", "Only weed bro" ]
  OFFSPRING_TYPES = [ "No Answer", "I have kids but they live elsewhere", "Kids at home", "NO" ]
  SMOKES_TYPES = [ "No Answer", "Yes", "No", "Occasionally", "Yes, but trying to quit", 
  		"When Drinking" ]
  ETHNICITY_TYPES = [ "No Answer", "White", "Black", "Asian", "Other" ]

  zipcode_regex = /[0-9]{5}/

  before_save :format_height
  

  validates :age, presence: true, numericality: true, inclusion: { in: 18..100 }
  validates :zipcode, presence: true, format: { with: zipcode_regex }
  validates :about_me, length: { maximum: 10000 }
  validates :good_at, length: { maximum: 5000 }
  validates :message_me_if, length: { maximum: 2000 }
  validates :relationship_status, inclusion: RELATIONSHIP_TYPES
  validates :sex, inclusion: [ "Male", "Female", "Both" ]
  validates :smokes, inclusion: SMOKES_TYPES
  validates :body_type, inclusion: BODY_TYPES
  validates :height, numericality: true, inclusion: { in: 36..90 }
  validates :drinks, inclusion: DRINKS_TYPES
  validates :religion, inclusion: RELIGION_TYPES
  validates :income, inclusion: INCOME_TYPES		
  validates :job, length: { maximum: 50 }
  validates :language, inclusion: LANGUAGE_TYPES
  validates :drugs, inclusion: DRUGS_TYPES
  validates :offspring, inclusion: OFFSPRING_TYPES
  validates :exercise, inclusion: EXERCISE_TYPES
  validates :ethnicity, inclusion: ETHNICITY_TYPES
  validates :interested_in, inclusion: INTERESTED_TYPES

  has_many :photos, dependent: :destroy
  accepts_nested_attributes_for :photos, allow_destroy: true

  has_many :sent_messages, class_name: "PrivateMessage", foreign_key: 'sender_id',
      dependent: :destroy
  has_many :received_messages, class_name: "PrivateMessage", foreign_key: 'receiver_id',
      dependent: :destroy

  has_many :sent_winks, class_name: "Wink", foreign_key: 'sender_id',
      dependent: :destroy
  has_many :received_winks, class_name: "Wink", foreign_key: 'receiver_id',
      dependent: :destroy
  has_many :favorites, class_name: 'Favorite', foreign_key: 'favoriter_id',
      dependent: :destroy
  has_many :favorited_by, class_name: 'Favorite', foreign_key: 'favoritee_id',
      dependent: :destroy  

  has_many :views, class_name: "View", foreign_key: "viewer_id", 
      dependent: :destroy
  has_many :reverse_views, class_name: "View", foreign_key: "viewed_id", 
      dependent: :destroy
  has_many :viewed_profiles, through: :views, source: :viewed
  has_many :viewed_by, through: :reverse_views, source: :viewer   
  has_many :searches, dependent: :destroy

  has_many :hidden_profiles, class_name: "Hidden", foreign_key: "sender_id", 
      dependent: :destroy
  has_many :reverse_hidden_profiles, class_name: "Hidden", foreign_key: "receiver_id",
      dependent: :destroy
  has_many :profiles_hidden, through: :hidden_profiles, source: :receiver
  has_many :profiles_hidden_by, through: :reverse_hidden_profiles, source: :sender


      
  belongs_to :user

  default_scope order: 'created_at DESC'
  scope :visible, where(hidden: false)

  def self.all_visible_profiles(profile)
    total_visible= visible - profile.profiles_hidden - profile.profiles_hidden_by
    total_visible.slice!(total_visible.index(profile)) if total_visible.include?(profile)
    total_visible
  end

  def self.hidden_and_hidden_by(profile)
    hidden_pro= (profile.profiles_hidden + profile.profiles_hidden_by)
    hidden_pro.slice!(hidden_pro.index(profile)) if hidden_pro.include?(profile)
    hidden_pro
  end

  def hide_own_profile(profiles)
    profiles.slice!(profiles.index(self)) if profiles.include?(self)
  end

  def has_main_photo?
    return photos.where(primary: true).first
  end
  
  def main_photo
    return photos.where(primary: true).first
  end

  def self.generate_random_profiles(profiles, search, search_profile= nil)
    unless search.new_record?
      profiles= Search.find(search).profiles.limit(15)
      profiles-= hidden_and_hidden_by(search_profile)
       #if search exists, return the associated profiles
      #limited at 10, or else just return random profiles as usual
    end  
    size= profiles.count
    size > 3 ? count=3 : count = size
    x= 0
    matches = []
    while (x < count)
      number= Random.rand(0..size-1)
      if !matches.include?(profiles[number])
        matches << profiles[number]
        x+=1
      end  
    end  
    return matches
  end

  def format_height
    feet= (self.height / 12).to_s
    inches= (self.height.remainder(12)).to_s
    self.formatted_height= feet+"'"+inches+'"'  
    # need self.x to change or access a varaible, otherwise it's just a local variable
    # needed a "before_save" block, so it changes the variable, then fires off the save in the controller
    # don't be so stupid next time
  end

  def sent_wink?(receiver_id)
    sent_winks.find_by_receiver_id(receiver_id)
  end

  def favorited?(favoritee_id)
    favorites.find_by_favoritee_id(favoritee_id)
  end

  def hid?(profile)
    hidden_profiles.find_by_receiver_id(profile.id)
  end

  def hide(profile)
    hidden_profiles.create!(receiver_id: profile.id)
  end

end
# == Schema Information
#
# Table name: profiles
#
#  id                  :integer         not null, primary key
#  about_me            :text
#  message_me_if       :text
#  good_at             :text
#  relationship_status :string(255)
#  age                 :integer
#  sex                 :string(255)
#  location            :string(255)
#  user_id             :integer
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  body_type           :string(255)     default("no answer")
#  height              :integer         default(65)
#  ethnicity           :string(255)     default("no answer")
#  smokes              :string(255)     default("no answer")
#  drinks              :string(255)     default("no answer")
#  religion            :string(255)     default("no answer")
#  income              :string(255)     default("no answer")
#  job                 :string(255)     default("no answer")
#  language            :string(255)     default("no answer")
#  drugs               :string(255)     default("no answer")
#  offspring           :string(255)     default("no answer")
#  exercise            :string(255)     default("no answer")
#  zip_code            :integer
#  nick_name           :string(255)
#  interested_in       :string(255)
#  zipcode             :string(255)
#  formatted_height    :string(255)
#  avatar_file_name    :string(255)
#  avatar_content_type :string(255)
#  avatar_file_size    :integer
#  avatar_updated_at   :datetime
#  hidden              :boolean         default(FALSE)
#  new_user            :boolean
#  photos_count        :integer
#

