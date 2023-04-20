require 'rubygems'
require 'bundler/setup'

require "sqlite3"

module CreateDatabase
  def self.run(db_file, loud = false)
    if File.exist?(db_file)
      abort("Database file `#{db_file}` already exists. Remove it and rerun to regenerate the database")
    end
  
    # Open a database
    db = SQLite3::Database.new db_file
    
    # Create a table
    rows = db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS locks (
        id TEXT PRIMARY KEY,
        key TEXT,
        locked BOOLEAN DEFAULT FALSE
      );
    SQL
    
    puts("Database created!") if loud
  end
end


# Can be run as a script
if $0 == __FILE__
  CreateDatabase::run "locks.db", true
end
