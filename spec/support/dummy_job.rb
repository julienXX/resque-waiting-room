require File.join(File.dirname(__FILE__) + '/../spec_helper')

class DummyJob
  extend Resque::Plugins::WaitingRoom
  can_be_performed times: 10, period: 30

  def self.perform(*_); end
end
