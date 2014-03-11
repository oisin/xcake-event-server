require 'bcrypt'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  field :email
  field :name
  field :password
  field :nonce
  field :admin, type: Boolean, :default => false
  field :auth_token
  field :auth_expiry, type: DateTime

  has_many :attendances

  before_create :hash_password

  def as_json(options={})
    {
      email: email,
      name: name
    }
  end

  # We store a nonce (salt) created by BCrypt in the DB. We also apply our own salt
  # to make things harder for someone who cracks the DB.
  def hash_password
    self.nonce = BCrypt::Engine.generate_salt
    self.password = BCrypt::Engine.hash_secret(salt + self.password, self.nonce)
  end

  def self.authenticate_with_token(token)
    u = User.where(auth_token: token).first
    if u && !u.auth_expiry.nil? && (Time.now.utc.to_i <= u.auth_expiry.utc.to_i)
      u
    else
      nil
    end
  end

  def self.authenticate_with_password(email, password)
    u = User.where(email: email).first
    if u && u.password == BCrypt::Engine.hash_secret(u.salt + password, u.nonce)
      u
    else
      nil
    end
  end

  def salt
    s = ENV['PASSWORD_SALT']
    raise ArgumentError.new("No PASSWORD_SALT environment variable defined") if s.nil?
    s
  end
end
