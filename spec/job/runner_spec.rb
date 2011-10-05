require 'spec_helper'
require 'support/test_observer'

describe Job::Runner do
  let(:job)      { stub('job:configure', :run => { :foo => 'foo' }) }
  let(:runner)   { Job::Runner.new(job) }
  let(:observer) { TestObserver.new }

  describe 'run' do
    before :each do
      runner.observers << observer
    end

    it 'notifies observers about the :start event' do
      runner.run
      observer.events.should include([:start, job])
    end

    it 'runs the job' do
      job.expects(:run)
      runner.run
    end

    describe 'with no exception happening' do
      it 'notifies observers about the :finish event' do
        runner.run
        observer.events.should include([:finish, job, { :result => { :foo => 'foo' } }])
      end
    end

    describe 'with an exception being raised in the job' do
      it 'logs the exception' do
        job.stubs(:run).raises(AssertionFailed.new(job, 'install'))
        runner.run
        event = observer.events.detect { |event| event.first == :log }
        event[1].should == job
        event[2][:output].should =~ /Error: .*: install/
      end

      it 'still notifies observers about the :finish event' do
        runner.run
        observer.events.should include([:finish, job, { :result => { :foo => 'foo' } }])
      end
    end
  end
end
