class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email
  field :name
  field :password
  field :nonce
  field :admin, :type => Boolean, :default => false

  has_many :attendances
end
