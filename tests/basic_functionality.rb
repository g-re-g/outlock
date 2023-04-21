# frozen_string_literal: true

ENV['APP_ENV'] = 'test'

require 'rubygems'
require 'bundler/setup'

require_relative '../main'
require_relative '../create_database'
require 'test/unit'
require 'rack/test'
require 'json'

# rubocop:disable Metrics/AbcSize
# Tests for the basic functionality of outlock
class OutlockBasicFunctionalityTest < Test::Unit::TestCase
  def setup
    CreateDatabase.run('test.db')
  end

  def teardown
    File.delete('test.db')
  end

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def post_json(url, params = '')
    post url, params, 'HTTP_ACCEPT' => 'application/json'
  end

  def test_home_page_works
    get '/'
    assert last_response.ok?
    assert last_response.body.include?('Out Lock')
  end

  def test_post_new_html
    post '/new'
    assert last_response.ok?
    assert last_response.body.include?('<!doctype html>')
    assert last_response.body.include?('id')
  end

  def test_post_new_json
    post_json('/new')
    assert last_response.ok?
    resp = JSON.parse(last_response.body)
    assert resp['id']
  end

  def test_post_new_with_key_html
    post '/new-with-key'
    assert last_response.ok?
    assert last_response.body.include?('<!doctype html>')
    assert last_response.body.include?('id')
    assert last_response.body.include?('key')
  end

  def test_post_new_with_key_json
    post '/new-with-key', '', 'HTTP_ACCEPT' => 'application/json'
    assert last_response.ok?
    resp = JSON.parse(last_response.body)
    assert resp['id']
    assert resp['key']
  end

  def test_post_lock
    lock_id = 'test_lock'
    post "/lock/#{lock_id}"
    assert last_response.ok?
    assert last_response.body.include?('<!doctype html>')
    assert last_response.body.include?('id')
    assert last_response.body.include?(lock_id)
    assert last_response.body.include?('previously_locked')
    assert last_response.body.include?('false')
  end

  def test_post_lock_json
    lock_id = 'test_lock'
    post_json "/lock/#{lock_id}"
    assert last_response.ok?
    resp = JSON.parse(last_response.body)
    assert_equal resp, {
      'id' => lock_id,
      'previously_locked' => false
    }
  end

  def test_post_unlock
    lock_id = 'test_lock'
    post "/unlock/#{lock_id}"
    assert last_response.ok?
    assert last_response.body.include?('<!doctype html>')
    assert last_response.body.include?('id')
    assert last_response.body.include?(lock_id)
    assert last_response.body.include?('previously_locked')
    assert last_response.body.include?('false')
  end

  def test_post_unlock_json
    lock_id = 'test_lock'
    post_json "/unlock/#{lock_id}"
    assert last_response.ok?
    resp = JSON.parse(last_response.body)
    assert_equal resp, {
      'id' => lock_id,
      'previously_locked' => false
    }
  end

  #
  # Multi endpoint tests
  #
  def test_lock_an_already_locked_lock_json
    lock_id = 'test_lock'
    post_json "/lock/#{lock_id}"
    assert last_response.ok?
    post_json "/lock/#{lock_id}"
    refute last_response.ok?
    assert_equal last_response.body, 'already locked'
  end

  # def test_get_new
  #   get '/new', :name => 'Simon'
  #   assert last_response.body.include?('Simon')
  # end
end
# rubocop:enable all
