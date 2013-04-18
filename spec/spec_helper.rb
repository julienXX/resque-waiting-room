require 'resque'
require 'mock_redis'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'resque-waiting-room'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'resque', 'plugins', 'waiting_room', 'matchers'))

RSpec.configure do |config|
  config.mock_framework = :rspec
end

puts "Using a mock Redis"
r = MockRedis.new host: "localhost", port: 9736, db: 0
$mock_redis = Redis::Namespace.new :resque, redis: r
Resque.redis = $mock_redis

# Require ruby files in support dir.
Dir[File.expand_path('spec/support/*.rb')].each { |file| require file }
