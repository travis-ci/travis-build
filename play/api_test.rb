require 'faraday'
require 'json'

conn = Faraday.new(:url => ENV['BUILD_API_SERVER_URL']) do |faraday|
  # faraday.response :logger
  faraday.adapter Faraday.default_adapter
end

data = eval DATA.read

response = conn.post do |req|
  req.url '/script'
  req.headers['Content-Type'] = 'application/json'
  req.headers['Authorization'] = "token #{ENV['API_TOKEN']}"

  req.body = data.to_json
end

puts response.body

__END__
{"type"=>"test",
 "build"=>
  {"id"=>21311478,
   "number"=>"4072.2",
   "commit"=>"6d7ffb15a816bbbf14b588edc954353efedb203c",
   "commit_range"=>"068bdd62c92c...6d7ffb15a816",
   "commit_message"=>"[Truffle] Annotate specs that also fail in JRuby.",
   "branch"=>"master",
   "ref"=>nil,
   "state"=>"passed",
   "secure_env_enabled"=>true,
   "pull_request"=>false},
 "job"=>
  {"id"=>21311478,
   "number"=>"4072.2",
   "commit"=>"6d7ffb15a816bbbf14b588edc954353efedb203c",
   "commit_range"=>"068bdd62c92c...6d7ffb15a816",
   "commit_message"=>"[Truffle] Annotate specs that also fail in JRuby.",
   "branch"=>"master",
   "ref"=>nil,
   "state"=>"passed",
   "secure_env_enabled"=>true,
   "pull_request"=>false},
 "source"=>{"id"=>21311476, "number"=>"4072"},
 "repository"=>
  {"id"=>10075,
   "slug"=>"jruby/jruby",
   "github_id"=>168370,
   "source_url"=>"git://github.com/jruby/jruby.git",
   "api_url"=>"https://api.github.com/repos/jruby/jruby",
   "last_build_id"=>21451782,
   "last_build_number"=>"4076",
   "last_build_started_at"=>"2014-03-24T19:25:29Z",
   "last_build_finished_at"=>"2014-03-24T20:16:31Z",
   "last_build_duration"=>9223,
   "last_build_state"=>"errored",
   "description"=>"JRuby, an implementation of Ruby on the JVM"},
 "config"=>
  {:language=>"java",
   :jdk=>"oraclejdk7",
   :env=>["TARGET='-Prake -Dtask=test:extended'"],
   :matrix=>
    {:include=>
      [{:env=>"TARGET='-Pdist'", :jdk=>"oraclejdk8"},
       {:env=>"TARGET='-Pjruby-jars'", :jdk=>"oraclejdk7"},
       {:env=>"TARGET='-Pmain'", :jdk=>"oraclejdk7"},
       {:env=>"TARGET='-Pcomplete'", :jdk=>"oraclejdk8"}],
     :fast_finish=>true,
     :allow_failures=>
      [{:env=>"TARGET='-Prake -Dtask=spec:ci_interpreted_ir_travis'"}]},
   :branches=>{:only=>["master", "jruby-1_7", "/^test-.*$/"]},
   :install=>"/bin/true",
   :notifications=>
    {:irc=>
      {:channels=>["irc.freenode.org#jruby"],
       :on_success=>"change",
       :on_failure=>"always",
       :template=>
        ["%{repository} (%{branch}:%{commit} by %{author}): %{message} (%{build_url})"]},
     :webhooks=>
      {:urls=>["https://rubies.travis-ci.org/rebuild/jruby-head"],
       :on_failure=>"never"}},
   :".result"=>"configured"},
 "queue"=>"builds.linux",
 "uuid"=>"121b7523-7629-4800-9a2b-0bc7b122d275"}
