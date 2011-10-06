require 'spec_helper'

describe 'Event' do
  let(:test_ruby) { Job::Test::Ruby.new(nil, nil, nil) }
  let(:configure) { Job::Configure.new(nil, nil) }

  describe 'name' do
    it 'returns "job:test:ruby:started" for a start event on a configure job' do
      event = Event.new(:started, test_ruby, nil)
      event.name.should == 'job:test:ruby:started'
    end

    it 'returns "job:test:ruby:started" for a start event on a ruby test job' do
      event = Event.new(:started, configure, nil)
      event.name.should == 'job:configure:started'
    end
 end
end
