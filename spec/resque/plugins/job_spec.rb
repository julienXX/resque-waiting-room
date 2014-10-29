require File.join(File.dirname(__FILE__) + '/../../spec_helper')

describe Resque::Job do

  before(:each) do
    Resque.redis.flushall
  end

  context "normal job" do
    it "should trigger original reserve" do
      Resque.push('normal', class: 'DummyJob', args: ['any args'])
      expect(Resque::Job.reserve('normal')).to eq(Resque::Job.new('normal', {'class' => 'DummyJob', 'args' => ['any args']}))
      expect(Resque::Job.reserve('waiting_room')).to eq(nil)
    end
  end

  context "waiting_room job" do
    it "should push in the waiting_room queue when reserve from waiting_room queue" do
      Resque.push('waiting_room', class: 'DummyJob', args: ['any args'])
      expect(Resque::Job.reserve('waiting_room')).to eq(Resque::Job.new('waiting_room', {'class' => 'DummyJob', 'args' => ['any args']}))
      expect(Resque::Job.reserve('normal')).to eq(nil)
    end

    it "should push back to waiting_room queue when still restricted" do
      Resque.push('waiting_room', class: 'DummyJob', args: ['any args'])
      expect(DummyJob).to receive(:repush).with('any args')
      expect(Resque::Job.reserve('waiting_room')).to eq(Resque::Job.new('waiting_room', {'class' => 'DummyJob', 'args' => ['any args']}))
      expect(Resque::Job.reserve('waiting_room')).to eq(nil)
      expect(Resque::Job.reserve('normal')).to eq(nil)
    end

    it "should not repush when reserve normal queue" do
      Resque.push('normal', class: 'DummyJob', args: ['any args'])
      expect(DummyJob).not_to receive(:repush).with('any args')
      expect(Resque::Job.reserve('normal')).to eq(Resque::Job.new('normal', {'class' => 'DummyJob', 'args' => ['any args']}))
      expect(Resque::Job.reserve('normal')).to eq(nil)
      expect(Resque::Job.reserve('waiting_room')).to eq(nil)
    end
  end

end
