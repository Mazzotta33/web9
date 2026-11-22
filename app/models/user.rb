class User < ApplicationRecord
  attr_accessor :remember_token

  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }
  before_save { email.downcase! }
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }

  # Returns a password digest, using a low cost in tests.
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Only the digest is stored in the database; the token goes into a cookie.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
    remember_digest
  end

  def authenticated?(token)
    return false if remember_digest.nil? || token.blank?

    BCrypt::Password.new(remember_digest).is_password?(token)
  end

  # Chapter 9 exercise: invalidate copied sessions when the digest changes.
  def session_token
    remember_digest || remember
  end

  def forget
    update_attribute(:remember_digest, nil)
  end
end
