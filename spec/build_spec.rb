require 'spec_helper'
require 'spec_helper/mocks'
require 'spec_helper/matchers'
require 'travis/build'

describe Travis::Build do
  let(:events)   { Travis::Build::Event::Factory.new(:id => 1) }
  let(:job)      { Travis::Build::Job::Configure.new(nil, nil) }
  let(:build)    { Travis::Build.new(events, job) }
  let(:observer) { Mocks::Observer.new }

  attr_reader :now

  before :each do
    @now = Time.now.utc
    Time.stubs(:now).returns(@now)
    job.stubs(:run).returns(:foo => 'foo')
    build.observers << observer
  end

  it 'implements a simple observer pattern' do
    build.send(:notify, :start, {})
    build.send(:notify, :log, {})
    build.send(:notify, :finish, {})
    observer.events.map { |event| event.first }.should == ['job:configure:start', 'job:configure:log', 'job:configure:finish']
  end

  describe 'run' do
    it 'notifies observers about the :start event' do
      build.run
      observer.events.should include_event('job:configure:start', :started_at => now)
    end

    it 'runs the job' do
      job.expects(:run).returns({})
      build.run
    end

    describe 'with no exception happening' do
      it 'notifies observers about the :finish event' do
        build.run
        observer.events.should include_event('job:configure:finish', :foo => 'foo', :finished_at => now)
      end
    end

    describe 'with a command timeout exception being raised' do
      it 'logs the exception' do
        job.stubs(:run).raises(Travis::Build::CommandTimeout.new(:script, 'rake', 1000))
        build.run
        observer.events.should include_event('job:configure:log', :log => /Executing your script \(rake\) took longer than 1000 seconds/)
      end
    end

    describe 'with an output exceeded exception being raised' do
      it 'logs the exception' do
        job.stubs(:run).raises(Travis::Build::OutputLimitExceeded.new(1000))
        build.run
        observer.events.should include_event('job:configure:log', :log => /The log length has exceeded the limit of 1000 Bytes/)
      end
    end

    describe 'with a standard error being raised' do
      it 'logs the exception' do
        job.stubs(:run).raises(StandardError.new('fatal'))
        build.run
        observer.events.should include_event('job:configure:log', :log => /fatal/)
      end

      it 'still notifies observers about the :finish event' do
        build.run
        observer.events.should include_event('job:configure:finish', :foo => 'foo', :finished_at => now)
      end
    end
  end
end
