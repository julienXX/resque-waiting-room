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
      expect { DummyJob.can_be_performed('lol') }.to raise_error(Resque::Plugins::WaitingRoom::MissingParams)
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

  context "custom matcher" do
    it "should match positive" do
      DummyJob.should be_only_performed(times: 10, period: 30)
    end
  end

  context "before_perform_waiting_room" do
    it "should call waiting_room_redis_key" do
      DummyJob.should_receive(:waiting_room_redis_key).and_return('DummyJob:remaining_performs')
      DummyJob.before_perform_waiting_room('args')
    end

    it "should call has_remaining_performs_key?" do
      DummyJob.should_receive(:has_remaining_performs_key?).and_return(false)
      DummyJob.before_perform_waiting_room('args')
    end

    it "should decrement performs" do
      DummyJob.before_perform_waiting_room('args')
      Resque.redis.get("DummyJob:remaining_performs").should =="9"
      DummyJob.before_perform_waiting_room('args')
      Resque.redis.get("DummyJob:remaining_performs").should =="8"
      DummyJob.before_perform_waiting_room('args')
      Resque.redis.get("DummyJob:remaining_performs").should =="7"
    end

    it "should prevent perform once there are no performs left" do
      9.times {DummyJob.before_perform_waiting_room('args')}
      Resque.redis.get("DummyJob:remaining_performs").should =="1"
      expect { DummyJob.before_perform_waiting_room('args') }.to raise_exception(Resque::Job::DontPerform)
    end

    it "should call ensure_has_expireation" do
      DummyJob.before_perform_waiting_room('args')
      DummyJob.should_receive(:ensure_has_expireation)
      DummyJob.before_perform_waiting_room('args')
    end
  end

  context "has_remaining_performs_key?" do
    it "should set a redis key" do
      Resque.redis.should_receive(:setnx)
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)
    end

    it "should expire the redis key" do
      Resque.redis.should_receive(:setnx).and_return(true)
      Resque.redis.should_receive(:expire)
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)
    end

    it "should not re-expire the redis key if it is already created" do
      Resque.redis.should_receive(:setnx).and_return(true)
      Resque.redis.should_receive(:expire)
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)
      Resque.redis.should_receive(:setnx).and_return(false)
      Resque.redis.should_not_receive(:expire)
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)
    end

    it "should return false if the key is new" do
      Resque.redis.should_receive(:setnx).and_return(true)
      Resque.redis.should_receive(:expire)
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key).should == false
    end

    it "should return true if the key was already created" do
      Resque.redis.should_receive(:setnx).and_return(false)
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key).should == true
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

  context "ensure_has_expireation" do
    it "should set expire to the key when it doesn't have any expiration" do
      Resque.redis.set(DummyJob.waiting_room_redis_key, 10)

      DummyJob.ensure_has_expireation(DummyJob.waiting_room_redis_key)
      Resque.redis.ttl(DummyJob.waiting_room_redis_key).should == 30
    end

    it "should not change expire when it has an expiration" do
      Resque.redis.set(DummyJob.waiting_room_redis_key, 10)
      Resque.redis.expire(DummyJob.waiting_room_redis_key, 15)

      DummyJob.ensure_has_expireation(DummyJob.waiting_room_redis_key)
      Resque.redis.ttl(DummyJob.waiting_room_redis_key).should == 15
    end
  end
end
