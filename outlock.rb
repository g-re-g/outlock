require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/json'
require 'uuidtools'
require "sqlite3"

#
# Boot
#
unless File.exist?('locks.db')
  abort("No database file. Run `ruby create_database.rb`")
end

#
# Public Routes
#

# About page
get '/' do
  erb :about
end

# Status of a lock
get '/status/:id', :provides => [:html, :json] do
  db = open_db
  lock = get_lock(db, params[:id])
  puts "Lock: #{lock}"
  locked = if lock then lock[:locked] else false end
  resp = {
    id: params[:id],
    locked: locked
  }

  respond_to do |format|
    format.json { resp.to_json }
    format.html { hash_to_html(resp)}
  end
end

# Get a new random lock and lock it
get '/new', :provides => [:html, :json] do
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

# Lock the lock
do_lock = lambda { |lock_id| do_lock_unlock(lock_id, true)}
get  '/lock/:id', :provides => [:html, :json], &do_lock
post '/lock/:id', :provides => [:html, :json], &do_lock

# Unlock the lock
do_unlock = lambda { |lock_id| do_lock_unlock(lock_id, false)}
get  '/unlock/:id', :provides => [:html, :json], &do_unlock
post '/unlock/:id', :provides => [:html, :json], &do_unlock

def do_lock_unlock(lock_id, locked) 
  db = open_db
  previously = set_lock(db, lock_id, locked)

  resp = {
    id: lock_id,
    previously_locked: previously
  }
  
  respond_to do |format|
    format.json { resp.to_json }
    format.html { hash_to_html(resp)}
  end
end

#
# Undocumented routes
#
get "/stats" do
  db = open_db
  erb :stats, locals: {num_locks: db.get_first_row("SELECT count(id) FROM locks")}
end

#
# Random helpers
#

def hash_to_html(hash)
  doc = '<!doctype html><html lang="en"><title>Out Doc - #{hash[:id]}</title><dl>'
  hash.each_pair do |key, value|
    doc += "<dt>#{key}</dt><dd>#{value}</dd>"
  end
  doc += "</dl></html>"
  doc
end


#
# DB Interactions
#
def open_db
  SQLite3::Database.new "locks.db"
end

def get_lock(db, lock_id, key = nil)
  case db.get_first_row("SELECT id,key,locked  FROM locks WHERE id=?", [lock_id])
  in nil
    nil
  in [id,key,locked]
    {id: id, key: key, locked: locked == "true"}
  end
end

def set_lock(db, lock_id, locked, key = nil)
  previously = false
  db.transaction do |db|
    case get_lock(db, lock_id)
    in nil
      db.execute("INSERT INTO locks(id, locked) VALUES (?, ?)", [lock_id, locked.to_s])
    in found
      previously = found[:locked]
      db.execute("UPDATE locks SET locked=? WHERE id=?", [locked.to_s, lock_id])
    end
  end
  previously
end

