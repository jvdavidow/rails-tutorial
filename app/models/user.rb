class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :omniauthable, :omniauth_providers => [:facebook]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :avatar, :avatar_cache
  attr_accessible :provider, :uid, :email_favorites
  
  has_many :posts
  has_many :comments
  has_many :votes, dependent: :destroy
  has_many :favorites, dependent: :destroy
  before_create :set_member

  mount_uploader :avatar, AvatarUploader


  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      pass = Devise.friendly_token[0,20]
      user = User.new(name:auth.extra.raw_info.name,
                         provider:auth.provider,
                         uid:auth.uid,
                         email:auth.info.email,
                         password: pass,
                         password_confirmation: pass
                        )
      user.skip_confirmation!
      user.save
    end
    user
  end

  def self.top_rated
    self.select('users.*'). # Select all attributes of the user
        select('COUNT(DISTINCT comments.id) AS comments_count'). # Create new "column" where we count the distinct comments
        select('COUNT(DISTINCT posts.id) AS posts_count'). # Create another column for posts
        select('COUNT(DISTINCT comments.id) + COUNT(DISTINCT posts.id) AS rank'). # Another column where we add them together to sort
        joins('LEFT OUTER JOIN posts ON posts.user_id = users.id'). # Need to join posts to count them
        joins('LEFT OUTER JOIN comments ON comments.user_id = users.id'). # Join comments to count them
        group('users.id'). # Tell Postgres how we want to group them together so it knows what to combine into "one" row
        order('rank DESC') # How to sort them
  end

  ROLES = %w[member moderator admin]
  def role?(base_role)
    role.nil? ? false : ROLES.index(base_role.to_s) <= ROLES.index(role)
  end

  def favorited(post)
    self.favorites.where(post_id: post.id).first
  end

  def voted(post)
    self.votes.where(post_id: post.id).first
  end


private

  def set_member
    self.role = 'member'
  end

end
