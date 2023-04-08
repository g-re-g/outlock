<img src="https://raw.githubusercontent.com/g-re-g/outlock/main/public/logo-light-square.png" width="200px">

# What?
A [synchronization lock](https://en.wikipedia.org/wiki/Lock_(computer_science)) as a service.

# Why?
* Maybe you want someone else to manage your syncronization primitives?
* Maybe you want make mutexes that have to make a network call to work?
* Maybe you have some distributed services that need to share a resource?

# TODO
* This is very much not complete and is in a good status to talk about what more needs to be done.

# Development

 - Make sure you have ruby 3.0 or higher installed
 - `bundle install` to install all the deps.
 - `ruby create_database.rb` to create the database.
 - `bundle exec rerun 'ruby outlock.rb'` for an auto-reloading dev server.
