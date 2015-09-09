# require all your dependences at one place
require 'simplecov'
require 'awesome_print'
require 'byebug'

# don't overwrite coverage reports automatically, explicitly ask for it.
if ENV['COVERAGE']
  SimpleCov.start do
    add_filter '/spec/'
  end
end

RSpec.configure do |config|
  # config you rspec test env
end
