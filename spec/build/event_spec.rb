require 'spec_helper'
require 'travis/build'

describe 'Event' do
  describe 'name' do
    Event     = Travis::Build::Event
    Test      = Travis::Build::Job::Test
    Configure = Travis::Build::Job::Configure

    it 'returns "job:test:started" for a start event on a clojure test job' do
      job = Test::Clojure.new(nil, nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a ruby test job' do
      job = Test::Ruby.new(nil, nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a erlang test job' do
      job = Test::Erlang.new(nil, nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a php test job' do
      job = Test::Php.new(nil, nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a NodeJS test job' do
      job = Test::NodeJs.new(nil, nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a Java test job' do
      job = Test::PureJava.new(nil, nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a Groovy test job' do
      job = Test::Groovy.new(nil, nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a Scala test job' do
      job = Test::Scala.new(nil, nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:ruby:started" for a start event on a configure job' do
      job = Configure.new(nil, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:configure:started'
    end
 end
end
