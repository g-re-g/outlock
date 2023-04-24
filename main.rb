# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/json'
require 'uuidtools'
require 'sqlite3'

#
# Boot
#
DB_FILE = ENV.fetch('APP_ENV', nil) == 'test' ? 'test.db' : 'locks.db'

#
# Public Routes
#

# About page
get '/' do
  erb :about
end

# Status of a lock
get '/status/:id', provides: %i[html json] do
  db = open_db
  lock = get_lock(db, params[:id])
  locked = lock ? lock[:locked] : false
  resp = {
    id: params[:id],
    locked: locked
  }

  respond(resp)
end

# Get a new random lock and lock it
post '/new', provides: %i[html json] do
  lock_id = UUIDTools::UUID.random_create.to_s
  resp = {
    id: lock_id
  }

  db = open_db
  set_lock(db, lock_id, true)

  respond(resp)
end

# Get a new random lock and lock it with a key
post '/new-with-key', provides: %i[html json] do
  lock_id = UUIDTools::UUID.random_create.to_s
  key = UUIDTools::UUID.random_create.to_s
  resp = {
    id: lock_id,
    key: key
  }

  db = open_db
  set_lock(db, lock_id, true, key)

  respond(resp)
end

# TODO: combine these into one route that may or may not have a key?
# TODO: test for nil or "" key?
post '/unlock-with-key/:id/:key', provides: %i[html json] do |lock_id, key|
  do_lock_unlock(lock_id, false, key)
end

post '/lock-with-key/:id/:key', provides: %i[html json] do |lock_id, key|
  do_lock_unlock(lock_id, true, key)
end

# Lock the lock
post '/lock/:id', provides: %i[html json] do |lock_id|
  do_lock_unlock(lock_id, true)
end

# Unlock the lock
post '/unlock/:id', provides: %i[html json] do |lock_id|
  do_lock_unlock(lock_id, false)
end

def do_lock_unlock(lock_id, set_to_locked, key = nil)
  db = open_db
  previously = set_lock(db, lock_id, set_to_locked, key)

  case previously
  when :incorrect_key
    403
  when :previously_locked
    406
  else
    resp = {
      id: lock_id,
      previously_locked: previously
    }
    resp[:key] = key if key
    respond(resp)
  end
end

#
# Undocumented routes
#
get '/stats' do
  db = open_db
  erb :stats, locals: { num_locks: db.get_first_row('SELECT count(id) FROM locks') }
end

#
# Random helpers
#

def hash_to_html(hash)
  doc = "<!doctype html><html lang=\"en=\"><title>Out Doc - #{hash[:id]}</title><dl>"
  hash.each_pair do |key, value|
    doc += "<dt>#{key}</dt><dd>#{value}</dd>"
  end
  doc += '</dl></html>'
  doc
end

def respond(resp)
  respond_to do |format|
    format.json { resp.to_json }
    format.html { hash_to_html(resp) }
  end
end

#
# HTTP Errors
#
error 403 do
  'incorrect key'
end

error 406 do
  'already locked'
end

#
# DB Interactions
#
def open_db
  abort("Database file `#{DB_FILE}` does not exist. Maybe run `ruby create_database.rb`") unless File.exist?(DB_FILE)
  SQLite3::Database.new DB_FILE
end

def get_lock(db, lock_id)
  result = db.get_first_row('SELECT id,key,locked  FROM locks WHERE id=?', [lock_id])
  return nil unless result && result.size == 3

  { id: result[0], key: result[1], locked: result[2] == 'true' }
end

def set_lock(database, lock_id, set_to_locked, key = nil)
  previously = false
  database.transaction do |db|
    result = get_lock(db, lock_id)

    if result
      return :incorrect_key unless result[:key] == key
      return :previously_locked if set_to_locked && result[:locked]

      previously = result[:locked]
      db.execute('UPDATE locks SET locked=? WHERE id=?', [set_to_locked.to_s, lock_id])
    else
      db.execute('INSERT INTO locks(id, key, locked) VALUES (?, ?, ?)', [lock_id, key, set_to_locked.to_s])
    end
  end

  previously
end
