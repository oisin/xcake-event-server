class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  validates_presence_of :n
  validates_format_of :o, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, message: 'must be a valid email address'

  field :n, as: :name
  field :o, as: :organizer
  field :l, as: :location
  field :d, as: :description

  field :st, type: DateTime, as: :starts
  field :et, type: DateTime, as: :ends

  has_many :attendances

  def as_json(options={})
    {
      name: n,
      organizer: o,
      location: l,
      description: d,
      starts: st.utc.to_i,
      ends: et.utc.to_i
    }
  end
end
