require "sqlite3"

if File.exist?('locks.db')
  abort("Database file already exists. Remove locks.db and rerun to regenerate the database")
end

# Open a database
db = SQLite3::Database.new "locks.db"

# Create a table
rows = db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS locks (
    id TEXT PRIMARY KEY,
    key TEXT,
    locked BOOLEAN DEFAULT FALSE
  );
SQL

puts("Database created!");
