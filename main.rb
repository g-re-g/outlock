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
DB_FILE = ENV['APP_ENV'] == 'test' ? 'test.db' : 'locks.db'

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

  respond_to do |format|
    format.json { resp.to_json }
    format.html { hash_to_html(resp) }
  end
end

# Get a new random lock and lock it
post '/new', provides: %i[html json] do
  lock_id = UUIDTools::UUID.random_create.to_s
  resp = {
    id: lock_id
  }

  db = open_db
  set_lock(db, lock_id, true)

  respond_to do |format|
    format.json { resp.to_json }
    format.html { hash_to_html(resp) }
  end
end

# Get a new random lock and lock it with a key
post '/new-with-key', provides: %i[html json] do
  lock_id = UUIDTools::UUID.random_create.to_s
  key = UUIDTools::UUID.random_create.to_s
  resp = {
    id: lock_id,
    key: UUIDTools::UUID.random_create.to_s
  }

  db = open_db
  set_lock(db, lock_id, true, key)

  respond(resp)
end

def respond(resp)
  respond_to do |format|
    format.json { resp.to_json }
    format.html { hash_to_html(resp) }
  end
end

# Lock the lock
post '/lock/:id', provides: %i[html json] do |lock_id|
  do_lock_unlock(lock_id, true)
end

# Unlock the lock
do_unlock = ->(lock_id) { do_lock_unlock(lock_id, false) }
get  '/unlock/:id', provides: %i[html json], &do_unlock
post '/unlock/:id', provides: %i[html json], &do_unlock

def do_lock_unlock(lock_id, set_to_locked)
  db = open_db
  previously = set_lock(db, lock_id, set_to_locked)

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

    respond_to do |format|
      format.json { resp.to_json }
      format.html { hash_to_html(resp) }
    end
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

def get_lock(db, lock_id, key = nil)
  result = db.get_first_row('SELECT id,key,locked  FROM locks WHERE id=?', [lock_id])
  if result && result.size == 3
    actual_key = result[1]
    if key == actual_key
      { id: result[0], key: result[1], locked: result[2] == 'true' }
    else
      :incorrect_key
    end
  end
end

def set_lock(db, lock_id, set_to_locked, key = nil)
  previously = false
  db.transaction do |db|
    result = get_lock(db, lock_id, key)
    if result == :incorrect_key
      return :incorrect_key
    elsif result
      previously = result[:locked]
      if set_to_locked && previously
        return :previously_locked
      else
        db.execute('UPDATE locks SET locked=? WHERE id=?', [set_to_locked.to_s, lock_id])
      end
    else
      db.execute('INSERT INTO locks(id, locked) VALUES (?, ?)', [lock_id, set_to_locked.to_s])
    end
  end
  previously
end
