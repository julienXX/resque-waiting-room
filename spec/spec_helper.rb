require 'spork'
require 'resque'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'resque-waiting-room'))

Spork.prefork do
  spec_dir = File.dirname(__FILE__)
  lib_dir  = File.expand_path(File.join(spec_dir, '..', 'lib'))
  $:.unshift(lib_dir)
  $:.uniq!
  RSpec.configure do |config|
    config.mock_framework = :rspec
  end

  # Require ruby files in support dir.
  Dir[File.expand_path('spec/support/*.rb')].each { |file| require file }
end
