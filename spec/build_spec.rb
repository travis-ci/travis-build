require 'spec_helper'
require 'travis/build'

describe Travis::Build do
  let(:events)   { Travis::Build::Event::Factory.new(:id => 1) }
  let(:commit) do
    Hashr.new(:repository => {
                :slug => "owner/repo",
              },
              :checkout => true)
  end
  let(:job)      { Travis::Build::Job::Test.new(nil, commit, nil) }
  let(:build)    { Travis::Build.new(events, job) }
  let(:observer) { Mocks::Observer.new }

  attr_reader :now

  before :each do
    @now = Time.now.utc
    Time.stubs(:now).returns(@now)
    job.stubs(:run).returns({ :result => 0 })
    build.observers << observer
  end

  it 'implements a simple observer pattern' do
    build.send(:notify, :start, {})
    build.send(:notify, :log, {})
    build.send(:notify, :finish, {})
    observer.events.map { |event| event.first }.should == ['job:test:start', 'job:test:log', 'job:test:finish']
  end

  describe 'run' do
    it 'notifies observers about the :start event' do
      build.run
      observer.events.should include_event('job:test:start', :started_at => now)
    end

    it 'runs the job' do
      job.expects(:run).returns({})
      build.run
    end

    describe 'with no exception happening' do
      it 'notifies observers about the :finish event' do
        build.run
        observer.events.should include_event('job:test:finish', :id => nil, :result => 0, :finished_at => now)
      end
    end

    describe 'with a standard error being raised' do
      before(:each) do
        job.stubs(:run).raises(StandardError.new('fatal'))
      end

      it 'logs the exception' do
        build.run
        friendly_message = "I'm sorry but an error occured within Travis while running your build."
        observer.events.should include_event('job:test:log', :log => /#{friendly_message}/)
        observer.events.should include_event('job:test:log', :log => /fatal/)
      end

      it 'still notifies observers about the :finish event' do
        job.stubs(:run).raises(StandardError.new('fatal'))
        build.run
        observer.events.should include_event('job:test:finish', :id => nil, :result => 1, :finished_at => now)
      end
    end
  end

  it "logs a vm stall message and fails the build" do
    build.vm_stall
    observer.events.should include_event('job:test:log',    :id => nil, :log => "\n\n\nI'm sorry but the VM stalled during your build and was not recoverable.")
    observer.events.should include_event('job:test:finish', :id => nil, :result => 1, :finished_at => now)
  end
end
