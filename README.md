![tests](https://github.com/g-re-g/outlock/actions/workflows/ruby-tests.yml/badge.svg)

<img src="https://raw.githubusercontent.com/g-re-g/outlock/main/public/logo-light-square.png" width="200px">

# What?
A [synchronization lock](https://en.wikipedia.org/wiki/Lock_(computer_science)) as a service.

Check it out here: outlock.greg.work

# Why?
* Maybe you want someone else to manage your syncronization primitives?
* Maybe you want make mutexes that have to make a network call to work?
* Maybe you have some distributed services that need to share a resource atomically?

# TODO
* Locks that expire after a timeout.
* Notify consumers when a lock has been unlocked or timedout.
* UDP / Websockets for faster communication with less overhead.

# Development

This is designed to run on Dreamhost's shared hosting and it is assumed to use:
* ruby 2.5.1
* Bundler version 1.16.1

Assuming you have those installed:

* `bundle install` to install all the deps.
* `ruby create_database.rb` to create the database.
* `bundle exec rerun 'ruby outlock.rb'` for an auto-reloading dev server.

# Tests

* `ruby tests/basic_functionality.rb`
