require File.join(File.dirname(__FILE__) + '/../spec_helper')


describe Resque::Job do
  Resque.redis = MockRedis.new

  class DummyJob
    extend Resque::Plugins::WaitingRoom
    can_be_performed :times => 1, :period => 10

    @queue = 'normal'

    def self.perform(args)
    end
  end

  before(:each) do
    Resque.redis.flushall
  end

  context "normal job" do
    it "should trigger original reserve" do
      Resque.push('normal', :class => 'DummyJob', :args => ['any args'])
      Resque::Job.reserve('normal').should == Resque::Job.new('normal', {'class' => 'DummyJob', 'args' => ['any args']})
      Resque::Job.reserve('normal').should be_nil
    end
  end

  context "waiting_room job" do
    it "should push in the waiting_room queue when reserve" do
      Resque.push('waiting_room', :class => 'DummyJob', :args => ['any args'])
      Resque::Job.reserve('waiting_room').should == Resque::Job.new('waiting_room', {'class' => 'DummyJob', 'args' => ['any args']})
      Resque::Job.reserve('normal').should be_nil
    end

    it "should push back to waiting_room queue when still restricted" do
      Resque.push('waiting_room', :class => 'DummyJob', :args => ['any args'])
      Resque.pop('waiting_room').should == {'class' => 'DummyJob', 'args' => ['any args']}
      Resque::Job.reserve('normal').should be_nil
    end

    it "should not repush when reserve normal queue" do
      Resque.push('normal', :class => 'DummyJob', :args => ['any args'])
      Resque::Job.reserve('normal').should == Resque::Job.new('normal', {'class' => 'DummyJob', 'args' => ['any args']})
      Resque::Job.reserve('normal').should be_nil
      Resque::Job.reserve('waiting_room').should be_nil
    end

    it "should only push back queue_length times to waiting_room queue" do
      # Resque.redis.set(WaitingRoomJob.redis_key(:per_hour), -1)
      3.times { Resque.push('waiting_room', :class => 'DummyJob', :args => ['any args']) }
      Resque.size('waiting_room').should == 3
      DummyJob.should_receive(:repush).exactly(3).times.and_return(true)
      Resque::Job.reserve('waiting_room')
    end
  end

end

