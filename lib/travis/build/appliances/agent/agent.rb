#!/usr/bin/env ruby

$stdout.sync = true
$stderr.sync = true

require 'fileutils'
require 'json'
require 'net/http'

def err(*strs)
  $stderr.puts(*strs)
end

module Agent
  PID = '/tmp/travis/agent.pid'
  DIR = '/tmp/travis/events'
  PAUSE = 0.2

  class Events
    attr_reader :queue, :watcher, :workers, :token

    def initialize
      @queue = Queue.new
      @workers = []
      trap_signals
    end

    def run
      refresh_token
      puts 'starting workers'
      5.times(&method(:work))
      puts 'starting watcher'
      @watcher = Watcher.new(queue)
      watcher.tap(&:start)
      puts 'stopped watching'
      sleep PAUSE
      workers.each(&:stop)
      puts 'removing pid'
      FileUtils.rm_rf(PID)
    end

    private

      def refresh_token
        @token = Refresh.new(ENV['TRAVIS_AGENT_REFRESH_JWT']).post
      end

      def work(num)
        workers << Worker.new(num + 1, queue, token).tap(&:start)
      end

      def stop(sig)
        puts "[stop] received signal #{sig}"
        watcher.stop
      rescue => e
        err e.message, e.backtrace
        exit
      end

      def trap_signals
        ['INT', 'TERM'].each { |sig| trap(sig, &method(:stop)) }
      end
  end

  class Watcher < Struct.new(:queue)
    include FileUtils

    def start
      mkdir_p DIR
      watch && sleep(PAUSE) until @stop
    end

    def stop
      @stop = true
      sleep(PAUSE)
      watch
    end

    def watch
      files.each(&method(:process))
    rescue => e
      err e.message
    end

    private

      def files
        Dir["#{DIR}/*"]
      end

      def process(file)
        puts "processing #{file}"
        queue.push(File.read(file))
        rm file
      end
  end

  class Worker < Struct.new(:num, :queue, :token)
    attr_reader :thread

    def start
      @thread = Thread.new { loop { send(queue.pop) } }
    end

    def stop
      puts "worker #{num} is busy ..." if busy?
      sleep 0.1 while busy?
      thread.exit
      puts "worker #{num} stopped"
    end

    private

      def busy?
        !!@busy
      end

      def send(data)
        @busy = true
        Event.new(token, data).post
        @busy = false
      end
  end

  class Http < Struct.new(:token, :data)
    URL = URI.parse('%{url}')

    def post(path, body = '')
      retrying(5) do
        res = client.post(path, body, headers)
        raise "error: #{res.code}" unless res.code.to_i == 200
        res.body
      end
    rescue => e
      err e.message
    end

    def headers
      {
        'Authorization' => "#{auth} #{token}",
        'Content-Type'  => 'application/json'
      }
    end

    def client
      Net::HTTP.new(URL.host, URL.port).tap do |http|
        http.use_ssl = true
        # http.set_debug_output $stderr
      end
    end

    def retrying(times, count = 0)
      count += 1
      yield
    rescue => e
      err e.message
      raise e if count > times
      err "retrying (#{count}/#{times}) ..."
      sleep 2 ** count
      retry
    end
  end

  class Refresh < Http
    def post
      puts 'refreshing token ...'
      super("#{URL.path}/token", data)
    end

    def auth
      :Refresh
    end
  end

  class Event < Http
    def post
      puts 'posting event ...'
      super("#{URL.path}/events", data)
      puts 'done posting event.'
    end

    def auth
      :Access
    end
  end
end

Agent::Events.new.run
