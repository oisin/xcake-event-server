class Attendance
  include Mongoid::Document
  include Mongoid::Timestamps

  field :i, type: Boolean, as: :interested, default: false
  field :a, type: Boolean, as: :attending, default: false
  belongs_to :user
  belongs_to :event
end
