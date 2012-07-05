require 'spec_helper'
require 'travis/build'

describe 'Event' do
  describe 'name' do
    Event     = Travis::Build::Event
    Test      = Travis::Build::Job::Test

    let(:commit) { Hashr.new(:repository => {
                             :slug => "owner/repo",
                           },
                           :checkout => true) }

    it 'returns "job:test:started" for a start event on a clojure test job' do
      job = Test::Clojure.new(nil, commit, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a ruby test job' do
      job = Test::Ruby.new(nil, commit, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a erlang test job' do
      job = Test::Erlang.new(nil, commit, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a php test job' do
      job = Test::Php.new(nil, commit, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a NodeJS test job' do
      job = Test::NodeJs.new(nil, commit, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a Java test job' do
      job = Test::PureJava.new(nil, commit, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a Groovy test job' do
      job = Test::Groovy.new(nil, commit, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end

    it 'returns "job:test:started" for a start event on a Scala test job' do
      job = Test::Scala.new(nil, commit, nil)
      event = Event.new(:started, job, nil)
      event.name.should == 'job:test:started'
    end
  end
end
