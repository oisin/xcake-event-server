require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'
require 'warden'

require_relative 'events'
require_relative 'users'
require_relative 'attendances'

class App < Sinatra::Base
  register Sinatra::Namespace
  set :show_exceptions, false

  MAJOR_VERSION = 1
  MINOR_VERSION = 0
  VERSION_REGEX = %r{/api/v(\d)\.(\d)}

  use Rack::Session::Cookie, secret: ENV['RACK_SECRET'] || "wibblewibblewubble"

  use Warden::Manager do |mang|
    mang.default_strategies :password, :token
    mang.failure_app = self
    mang.serialize_into_session { |user| user._id }
    mang.serialize_from_session { |id| User.find(id) }
  end

  Warden::Strategies.add(:token) do
    def authenticate!
      user = User.authenticate_with_token(params['token'])
      user.nil? ? fail!({errors: ['invalid token']}.to_json) : success!(user)
    end
  end

  Warden::Strategies.add(:password) do
    def valid?
      env['credentials']['email'] && env['credentials']['password']
    end

    def authenticate!
      user = User.authenticate_with_password(env['credentials']['email'], env['credentials']['password'])
      unless user.nil?
        user.auth_token = SecureRandom.urlsafe_base64
        user.auth_expiry = Time.now.utc + (24 * 60 * 60) # expire after 24 hours
        user.save
        custom! [200, {}, { token: user.auth_token }.to_json]
      else
        custom! [403, {}, {errors: ['invalid email or password']}]
      end
    end
  end

  configure do
    Mongoid.configure do |config|
      Mongoid.logger = nil
      Mongoid.raise_not_found_error = true
      Mongoid.load!("mongoid.yml")
    end
  end


  # Auth fails. No bacon.
  post '/unauthenticated' do
    halt 403, { errors: ['you need to log in now']}.to_json
  end

  get '/dbsetup' do
    puts "Setting up database"
    u = User.where(email: 'o@converser.io').first
    if u.nil?
      us = User.create {|u|
        u.email = "o@converser.io"
        u.name = "Oisin Hurley"
        u.admin = true
        u.password = "wibble"
      }

      events = []
      %w{event1 event2 event3 event4}.each_with_index {|name, inx|
        events[inx] = Event.create {|ev|
          ev.name = name
          ev.organizer = 'o@converser.io'
          ev.location = "Science Gallery"
          ev.description = "Some kind of a hoolie"
          day = rand(27) + 1
          month = rand(11) + 1
          ev.starts = Time.gm(2014, month, day, 18, 30).utc
          ev.ends =  Time.gm(2014, month, day, 20, 30).utc
        }

        att = Attendance.create {|a|
          a.interested = (rand(10) > 5)
          a.attending = (rand(10) <= 5)
          a.user = us
          a.event = events[inx]
        }
      }

    end
  end

  namespace '/api' do
    get '/events' do
      # return all the public events and include data if they are interested/attending
      # by the current user if there is one
      result = []
      Event.all.desc(:when).each { |ev|
        hash = ev.as_json

        if env['warden'].user
          if (my = Attendance.where(user: env['warden'].user, event: ev).first)
            hash['interested'] = my.interested
            hash['attending'] = my.attending
          end
        end
        result << hash
      }

      result.to_json
    end

    get '/event/:id' do
      result = {}
      begin
        ev_hash = Event.find(params[:id]).as_json
        unless env['warden'].authenticate(:token).nil?
          att = env['warden'].user.attendances.where(event: params[:id]).first
          ev_hash['interested'] = att.interested
          ev_hash['attending'] = att.attending
        end
        ev_hash.to_json
      rescue Exception => e
        halt 404
      end
    end

    post '/event/:id' do
      env['warden'].authenticate!(:token)

      begin
        marks = JSON.parse(request.body.read)
        ev = Event.find(params[:id])
        att = Attendance.where(event: params[:id]).first
        if att.nil?
          att = Attendance.new(event: ev, user: current_user)
        end
        att.interested = marks['interested'] if marks['interested']
        att.attending = marks['attending'] if marks['attending']
        att.save
        if att.errors.empty?
          halt 200
        else
          halt 400, { errors: att.errors }.to_json
        end
      rescue StandardError => e
        halt 404
      end
    end

    post '/login' do
      require 'pry' ; bindings.pry
      env['credentials'] = JSON.parse(request.body.read)
      env['warden'].authenticate!(:password)
    end

    post '/logout' do   # TODO: does this mean clear the token too.
      env['warden'].logout
    end

    post '/register' do
      data = JSON.parse(request.body.read)
      u = User.where(email: data['email']).first
      if u.nil?
        u = User.create { |u|
          u.email = data['email']
          u.password = data['password']
          u.auth_token = SecureRandom.urlsafe_base64
          u.auth_expiry = Time.now.utc + (24 * 60 * 60) # expire after 24 hours
        }
        u.save
        unless u.errors.empty?
          halt 400, {errors: u.errors}.to_json
        else
          halt 201, { token: u.auth_token }.to_json
        end
      else
        halt 409, {errors: ['email already registered']}.to_json
      end
    end
  end

  helpers do
    def version_compatible?(nums)
      return MAJOR_VERSION == nums[0].to_i && MINOR_VERSION >= nums[1].to_i
    end

    def current_user
      User.where(email: "o@converser.io").first
    end
  end

  before do
    content_type 'application/json'
  end

  before VERSION_REGEX do
    if version_compatible?(params[:captures])
      request.path_info = '/api' + request.path_info.match(VERSION_REGEX).post_match
    else
      halt 400,  {errors: ['version not compatible with this server']}.to_json
    end
  end
end
