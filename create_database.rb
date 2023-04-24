# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'sqlite3'

# Outlock namespace
module Outlock
  # Creates and migrates the sqlite3 database
  module CreateDatabase
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
end

# Can be run as a script
Outlock::CreateDatabase.run('locks.db', true) if $PROGRAM_NAME == __FILE__
