require File.join(File.dirname(__FILE__) + '/../../spec_helper')

describe Resque::Plugins::WaitingRoom do
  before(:each) do
    Resque.redis.flushall
  end

  it "should validate the Resque linter" do
    Resque::Plugin.lint(Resque::Plugins::WaitingRoom)
  end

  context "can_be_performed" do
    it "should raise InvalidParams" do
      expect {DummyJob.can_be_performed('lol')}.should raise_error(Resque::Plugins::WaitingRoom::MissingParams)
    end

    it "should assign @period and @max_performs" do
      DummyJob.instance_variable_get("@period").should == 30
      DummyJob.instance_variable_get("@max_performs").should == 10
    end
  end

  context "waiting_room_redis_key" do
    it "should generate a redis key name based on the class" do
      DummyJob.waiting_room_redis_key.should == 'DummyJob:remaining_performs'
    end
  end

  context "before_perform_waiting_room" do
    it "should call waiting_room_redis_key" do
      DummyJob.should_receive(:waiting_room_redis_key).and_return('DummyJob:remaining_performs')
      DummyJob.before_perform_waiting_room('args')
    end

    it "should call count_key" do
      DummyJob.should_receive(:count_key).and_return(false)
      DummyJob.before_perform_waiting_room('args')
    end

    it "should decrement performs" do
      DummyJob.before_perform_waiting_room('args')
      Resque.redis.get("DummyJob:remaining_performs").should =="9"
    end

    it "should prevent perform once there are no performs left" do
      9.times {DummyJob.before_perform_waiting_room('args')}
      Resque.redis.get("DummyJob:remaining_performs").should =="1"
      expect { DummyJob.before_perform_waiting_room('args') }.should raise_exception(Resque::Job::DontPerform)
    end
  end

  context "count_key" do
    it "should set a redis key" do
      Resque.redis.should_receive(:setnx)
      DummyJob.count_key(DummyJob.waiting_room_redis_key, 10)
    end

    it "should expire the redis key with period" do
      Resque.redis.should_receive(:setnx).and_return(true)
      Resque.redis.should_receive(:expire)
      DummyJob.count_key(DummyJob.waiting_room_redis_key, 10)
    end

    it "should not re-expire the redis key if it is already created" do
      Resque.redis.should_receive(:setnx).and_return(false)
      Resque.redis.should_not_receive(:expire)
      DummyJob.count_key(DummyJob.waiting_room_redis_key, 10)
    end

    it "should return false if the key was created" do
      Resque.redis.should_receive(:setnx).and_return(true)
      Resque.redis.should_receive(:expire)
      DummyJob.count_key(DummyJob.waiting_room_redis_key, 10).should == false
    end

    it "should return true if the kay was already created" do
      Resque.redis.should_receive(:setnx).and_return(false)
      DummyJob.count_key(DummyJob.waiting_room_redis_key, 10).should == true
    end
  end

  context "repush" do
    it "should call waiting_room_redis_key" do
      DummyJob.should_receive(:waiting_room_redis_key).and_return('DummyJob:remaining_performs')
      DummyJob.repush('args')
    end

    it "should get the key" do
      Resque.redis.should_receive(:get).with(DummyJob.waiting_room_redis_key)
      DummyJob.repush('args')
    end

    it "should push in the waiting_room if there are no performs left" do
      Resque.redis.should_receive(:get).with(DummyJob.waiting_room_redis_key).and_return('0')
      Resque.should_receive(:push).with('waiting_room', class: 'DummyJob', args: ['args']).and_return(true)
      DummyJob.repush('args')
    end

    it "should return true if there were no performs left" do
      Resque.redis.should_receive(:get).with(DummyJob.waiting_room_redis_key).and_return('0')
      DummyJob.repush('args').should == true
    end

    it "should return false if there were performs left" do
      Resque.redis.should_receive(:get).with(DummyJob.waiting_room_redis_key).and_return('1')
      DummyJob.repush('args').should == false
    end
  end

end

