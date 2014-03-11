require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

require_relative '../app'

class EventTests < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    App
  end

  def setup
    @email = "o@converser.io"
    @passwd = "wibble"
    @user = User.create {|u|
      u.email = @email
      u.name = "Oisin Hurley"
      u.admin = true
      u.password = @passwd
    }
  end

  def teardown
    Event.delete_all
    User.delete_all
    Attendance.delete_all
  end

  def test_no_events
    Event.delete_all

    get '/api/v1.0/events'

    assert_equal 200, last_response.status

    result = JSON.parse(last_response.body)
    assert result.is_a?(Array)
    assert result.empty?
  end

  def test_get_events
    events = []
    day = 10
    %w{event1 event2 event3 event4}.each_with_index {|name, inx|
      events[inx] = Event.create {|ev|
        ev.name = name
        ev.organizer = 'o@converser.io'
        ev.location = "Science Gallery"
        ev.description = "Some kind of a hoolie"
        ev.starts = Time.gm(2014, 6, day, 18, 30).utc
        ev.ends =  Time.gm(2014, 6, day, 20, 30).utc
        day -= 1
      }
    }

    get '/api/v1.0/events'
    assert_equal 200, last_response.status
    result = JSON.parse(last_response.body)

    assert result.is_a?(Array)
    assert_equal events.count, result.count

    # TODO: compare deeep
  end

  def test_get_one_event
    event = handy_event
    get "/api/v1.0/event/#{event._id}"

    assert_equal 200, last_response.status
    result = JSON.parse(last_response.body)

    assert_equal event.name, result['name']
    assert_equal event.organizer, result['organizer']
    assert_equal event.location, result['location']
    assert_equal event.description, result['description']
    assert_equal event.starts.to_i, result['starts']
    assert_equal event.ends.to_i, result['ends']
  end

  def test_event_interested
    event = handy_event

    req = {
      interested: true
    }

    post "/api/v1.0/login", {email: @email, password: @passwd}.to_json
    assert_equal 200, last_response.status
    auth_token = JSON.parse(last_response.body)['token']
    refute_nil auth_token, 'no auth token'

    post "/api/v1.0/event/#{event._id}?token=#{auth_token}", req.to_json
    assert_equal 200, last_response.status

    get "/api/v1.0/event/#{event._id}"
    assert_equal 200, last_response.status

    result = JSON.parse(last_response.body)
    assert result['interested']
    refute result['attendings']
  end

  def test_event_attending
    event = handy_event

    req = {
      attending: true
    }

    post "/api/v1.0/login", {email: @email, password: @passwd}.to_json
    assert_equal 200, last_response.status
    auth_token = JSON.parse(last_response.body)['token']
    refute_nil auth_token, 'no auth token'

    post "/api/v1.0/event/#{event._id}?token=#{auth_token}", req.to_json
    assert_equal 200, last_response.status

    get "/api/v1.0/event/#{event._id}"
    assert_equal 200, last_response.status

    result = JSON.parse(last_response.body)
    assert result['attending']
    refute result['interested']
  end

  def test_register_user
    event = handy_event

    data = {
      email: 'foo@bar.com',
      password: 'wobble'
    }

    post "/api/v1.0/register", data.to_json  # logs you in as well
    assert_equal 201, last_response.status
    auth_token = JSON.parse(last_response.body)['token']
    refute_nil auth_token, 'no auth token'

    u = User.where(email: 'foo@bar.com').first
    refute_nil u, 'Cannot find registered user'

    req = {
      attending: true
    }
    post "/api/v1.0/event/#{event._id}?token=#{auth_token}", req.to_json
    assert_equal 200, last_response.status
  end

  def test_no_dup_register_user
    data = {
      email: @email,
      password: @passwd
    }

    post "/api/v1.0/register", data.to_json
    assert_equal 409, last_response.status  #already registered
  end

  def handy_event
    Event.create {|ev|
      ev.name = "Wonder Event"
      ev.organizer = 'o@converser.io'
      ev.location = "Science Gallery"
      ev.description = "Some kind of a hoolie"
      ev.starts = Time.gm(2014, 6, 3, 18, 30).utc
      ev.ends =  Time.gm(2014, 6, 3, 20, 30).utc
    }
  end
end
