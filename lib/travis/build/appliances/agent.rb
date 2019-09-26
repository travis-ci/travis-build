require 'base64'
require 'travis/build/appliances/base'
require 'travis/build/appliances/agent/jwt'
require 'travis/build/git'

module Travis
  module Build
    module Appliances
      class Agent < Base
        include Base64

        TTL = 3 * 60 * 60

        def apply?
          ENV['TRAVIS_AGENT'] && linux?
        end

        def apply
          logger.info "Starting agent for job_id=#{job_id} owner_name=#{owner_name}"
          install
          start
          store_key
        end

        private

          def install
            sh.raw <<~sh
              mkdir -p ~/.travis /tmp/travis/events
              echo "#{strict_encode64(agent)}" | base64 --decode > ~/.travis/agent
              chmod +x ~/.travis/agent
            sh
          end

          def start
            sh.raw "TRAVIS_AGENT_REFRESH_JWT=#{token} ~/.travis/agent > /tmp/travis/agent.log 2>&1 &"
            sh.raw 'echo $! > /tmp/travis/agent.pid'
          end

          def store_key
            redis.set(key, 1, ex: TTL)
          end

          def agent
            str = File.read(path) % { url: "#{ENV['HUB_URL']}/jobs/#{job_id}" }
            str.untaint
          end

          def path
            File.expand_path('../agent/agent.rb', __FILE__)
          end

          def key
            @key ||= ['jwt-refresh', job_id, jwt.rand].join(':')
          end

          def token
            jwt.create.untaint
          end

          def jwt
            @jwt ||= Jwt::RefreshToken.new(private_key, job_id, :org)
          end

          def private_key
            OpenSSL::PKey::RSA.new(decode64(ENV['JWT_RSA_PRIVATE_KEY']))
          end

          def job_id
            data.job[:id]
          end

          def owner_name
            data.slug.split('/').first
          end

          def logger
            Build.logger
          end

          def redis
            Build.redis
          end
      end
    end
  end
end
