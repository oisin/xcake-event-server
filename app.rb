require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'

require_relative 'events'
require_relative 'users'
require_relative 'attendances'

class App < Sinatra::Base
  register Sinatra::Namespace
  set :show_exceptions, false

  MAJOR_VERSION = 1
  MINOR_VERSION = 0
  VERSION_REGEX = %r{/api/v(\d)\.(\d)}

  configure do
    Mongoid.configure do |config|
      Mongoid.logger = nil
      Mongoid.raise_not_found_error = true
      Mongoid.load!("mongoid.yml")
    end
  end

  namespace '/api' do
    get '/events' do
      Event.all.desc(:when).to_a.to_json
    end

    get '/event/:id' do
      result = {}
      begin
        ev_hash = Event.find(params[:id]).as_json
        att = current_user.attendances.where(event: params[:id]).first
        unless att.nil?
          ev_hash['interested'] = att.interested
          ev_hash['attending'] = att.attending
        else
          ev_hash['interested'] = ev_hash['attending'] = false
        end
        ev_hash.to_json
      rescue Exception => e
        halt 404
      end
    end

    post '/event/:id' do
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
      rescue StandardError => e
        halt 404
      end
    end

    post '/register' do
      data = JSON.parse(request.body.read)
      u = User.where(email: data['email']).first
      if u.nil?
        u = User.create { |u|
          u.email = data['email']
          u.password = data['password']
        }
        u.save
        unless u.errors.empty?
          halt 400, {errors: u.errors}.to_json
        else
          201
        end
      else
        halt 400, {errors: ['email already registered']}.to_json
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
