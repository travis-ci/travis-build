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
    job.stubs(:run).returns({ :status => 0 })
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
        observer.events.should include_event('job:test:finish', :id => nil, :status => 0, :finished_at => now)
      end
    end

    describe 'with a command timeout exception being raised' do
      it 'logs the exception' do
        job.stubs(:run).raises(Travis::Build::CommandTimeout.new(:script, 'rake', 1000))
        build.run
        observer.events.should include_event('job:test:log', :log => /Executing your script \(rake\) took longer than 1000 seconds/)
      end
    end

    describe 'with an output exceeded exception being raised' do
      it 'logs the exception' do
        job.stubs(:run).raises(Travis::Build::OutputLimitExceeded.new(1000))
        build.run
        observer.events.should include_event('job:test:log', :log => /The log length has exceeded the limit of 1000 Bytes/)
      end
    end

    describe 'with a standard error being raised' do
      it 'logs the exception' do
        job.stubs(:run).raises(StandardError.new('fatal'))
        build.run
        observer.events.should include_event('job:test:log', :log => /fatal/)
      end

      it 'still notifies observers about the :finish event' do
        build.run
        observer.events.should include_event('job:test:finish', :id => nil, :status => 0, :finished_at => now)
      end
    end
  end
end
