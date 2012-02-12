require File.join(File.dirname(__FILE__) + '/../../spec_helper')

describe Resque::Job do
  before(:each) do
    Resque.redis.flushall
  end

  context "normal job" do
    it "should trigger original reserve" do
      Resque.push('normal', :class => 'DummyJob', :args => ['any args'])
      Resque::Job.reserve('normal').should == Resque::Job.new('normal', {'class' => 'DummyJob', 'args' => ['any args']})
      Resque::Job.reserve('waiting_room').should be_nil
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
      DummyJob.should_receive(:repush).with('any args')
      Resque::Job.reserve('waiting_room').should == Resque::Job.new('waiting_room', {'class' => 'DummyJob', 'args' => ['any args']})
      Resque::Job.reserve('normal').should be_nil
    end

    it "should not repush when reserve normal queue" do
      Resque.push('normal', :class => 'DummyJob', :args => ['any args'])
      Resque::Job.reserve('normal').should == Resque::Job.new('normal', {'class' => 'DummyJob', 'args' => ['any args']})
      Resque::Job.reserve('normal').should be_nil
      Resque::Job.reserve('waiting_room').should be_nil
    end
  end

end

