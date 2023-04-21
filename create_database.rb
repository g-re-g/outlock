# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'sqlite3'

# Creates and migrates the sqlite3 database
module OutlockCreateDatabase
  # Creates and migrates the sqlite3 database

  def self.run(db_file, loud: false)
    if File.exist?(db_file)
      abort("Database file `#{db_file}` already exists. Remove it and rerun to regenerate the database")
    end

    # Open a database
    db = SQLite3::Database.new db_file

    # Create a table
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS locks (
        id TEXT PRIMARY KEY,
        key TEXT,
        locked BOOLEAN DEFAULT FALSE
      );
    SQL

    puts('Database created!') if loud
  end
end

# Can be run as a script
CreateDatabase.run('locks.db', true) if $PROGRAM_NAME == __FILE__
