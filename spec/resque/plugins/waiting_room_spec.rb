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
      expect(DummyJob.instance_variable_get("@period")).to eq(30)
      expect(DummyJob.instance_variable_get("@max_performs")).to eq(10)
    end
  end

  context "waiting_room_redis_key" do
    it "should generate a redis key name based on the class" do
      expect(DummyJob.waiting_room_redis_key).to eq('DummyJob:remaining_performs')
    end
  end

  context "custom matcher" do
    it "should match positive" do
      expect(DummyJob).to be_only_performed(times: 10, period: 30)
    end
  end

  context "before_perform_waiting_room" do
    it "should call waiting_room_redis_key" do
      expect(DummyJob).to receive(:waiting_room_redis_key).and_return('DummyJob:remaining_performs')
      DummyJob.before_perform_waiting_room('args')
    end

    it "should call has_remaining_performs_key?" do
      expect(DummyJob).to receive(:has_remaining_performs_key?).and_return(false)
      DummyJob.before_perform_waiting_room('args')
    end

    it "should decrement performs" do
      DummyJob.before_perform_waiting_room('args')
      expect(Resque.redis.get("DummyJob:remaining_performs")).to eq("9")
      DummyJob.before_perform_waiting_room('args')
      expect(Resque.redis.get("DummyJob:remaining_performs")).to eq("8")
      DummyJob.before_perform_waiting_room('args')
      expect(Resque.redis.get("DummyJob:remaining_performs")).to eq("7")
    end

    it "should prevent perform once there are no performs left" do
      9.times {DummyJob.before_perform_waiting_room('args')}
      expect(Resque.redis.get("DummyJob:remaining_performs")).to eq("1")
      expect { DummyJob.before_perform_waiting_room('args') }.to raise_exception(Resque::Job::DontPerform)
    end
  end

  context "has_remaining_performs_key?" do
    before do
      @key = DummyJob.waiting_room_redis_key
      @max = DummyJob.instance_variable_get("@max_performs") - 1 
      @period = DummyJob.instance_variable_get("@period")
    end
    it "should set a redis key" do
      expect(Resque.redis).to receive(:set).with(@key, @max,{ ex: @period, nx: false })
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)
    end

    it "should expire the redis key" do
      expect(Resque.redis).to receive(:set).with(@key, @max,{ ex: @period, nx: false }).and_return(true)
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)
    end

    it "should not re-expire the redis key if it is already created" do
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)
      expect(Resque.redis).to receive(:set).with(@key, @max,{ ex: @period, nx: true }).and_return(false)
      DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)
    end

    it "should return false if the key is new" do
      expect(Resque.redis).to receive(:set).with(@key, @max,{ ex: @period, nx: false }).and_return(true)
      expect(DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)).to eq(false)
    end

    it "should return true if the key was already created" do
      expect(Resque.redis).to receive(:set).with(@key, @max,{ ex: @period, nx: false }).and_return(false)
      expect(DummyJob.has_remaining_performs_key?(DummyJob.waiting_room_redis_key)).to eq(true)
    end
  end

  context "repush" do
    it "should call waiting_room_redis_key" do
      expect(DummyJob).to receive(:waiting_room_redis_key).and_return('DummyJob:remaining_performs')
      DummyJob.repush('args')
    end

    it "should get the key" do
      expect(Resque.redis).to receive(:get).with(DummyJob.waiting_room_redis_key)
      DummyJob.repush('args')
    end

    it "should push in the waiting_room if there are no performs left" do
      expect(Resque.redis).to receive(:get).with(DummyJob.waiting_room_redis_key).and_return('0')
      expect(Resque).to receive(:push).with('waiting_room', class: 'DummyJob', args: ['args']).and_return(true)
      DummyJob.repush('args')
    end

    it "should return true if there were no performs left" do
      expect(Resque.redis).to receive(:get).with(DummyJob.waiting_room_redis_key).and_return('0')
      expect(DummyJob.repush('args')).to eq(true)
    end

    it "should return false if there were performs left" do
      expect(Resque.redis).to receive(:get).with(DummyJob.waiting_room_redis_key).and_return('1')
      expect(DummyJob.repush('args')).to eq(false)
    end
  end

end
