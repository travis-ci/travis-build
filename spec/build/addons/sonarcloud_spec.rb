require 'spec_helper'

describe Travis::Build::Addons::Sonarcloud, :sexp do
  let(:script) { stub('script') }
  let(:config) { :true }

  let(:job)    { { :branch => 'master' } }
  let(:data)   { payload_for(:push, :ruby, job: job, config: { addons: { sonarcloud: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_before_script }

  it_behaves_like 'compiled script' do
    
  end

  describe 'scanner and build wrapper installation' do
    it { should include_sexp [:export, ['SONAR_SCANNER_HOME', '${TRAVIS_HOME}/.sonarscanner/sonar-scanner'], {:echo=>true}] }
    it { should include_sexp [:export, ['PATH', "\"$PATH:${TRAVIS_HOME}/.sonarscanner/sonar-scanner/bin\""]] }
    it { should include_sexp [:mkdir, "$sq_build_wrapper_dir", {:recursive=>true}] }
    it { should include_sexp [:export, ['PATH', "\"$PATH:$sq_build_wrapper_dir/build-wrapper-linux-x86\""]] }
  end

  describe 'skip build wrapper installation with java' do
    let(:data) { super().merge(config: { :language => 'java' })}

    it { should include_sexp [:export, ['SONAR_SCANNER_HOME', '${TRAVIS_HOME}/.sonarscanner/sonar-scanner'], {:echo=>true}] }
    it { should include_sexp [:export, ['PATH', "\"$PATH:${TRAVIS_HOME}/.sonarscanner/sonar-scanner/bin\""]] }
    it { should_not include_sexp [:mkdir, "$sq_build_wrapper_dir", {:recursive=>true}] }
    it { should_not include_sexp [:export, ['PATH', "\"$PATH:$sq_build_wrapper_dir/build-wrapper-linux-x86\""]] }
  end

  describe 'skip build wrapper with invalid OS' do
    let(:data) { super().merge(config: { :language => 'unkown' })}

    it { should include_sexp [:export, ['SONAR_SCANNER_HOME', '${TRAVIS_HOME}/.sonarscanner/sonar-scanner'], {:echo=>true}] }
    it { should include_sexp [:export, ['PATH', "\"$PATH:${TRAVIS_HOME}/.sonarscanner/sonar-scanner/bin\""]] }
    it { should include_sexp [:echo, "Can't install SonarSource build wrapper for platform: $TRAVIS_OS_NAME.", {:ansi=>:red}] }
    it { should_not include_sexp [:export, ['PATH', "\"$PATH:$sq_build_wrapper_dir/build-wrapper-linux-x86\""]] }
  end

  describe 'new pull request analysis' do
    let(:job) { super().merge( {:pull_request => '123', :pull_request_head_branch => 'master' })}

    it { should_not include_sexp [:export, ['SONAR_GITHUB_TOKEN', 'mytoken' ]] }
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS',
      "\"{ \\\"sonar.pullrequest.key\\\" : \\\"123\\\", \\\"sonar.pullrequest.branch\\\" : \\\"master\\\", \\\"sonar.pullrequest.base\\\" : \\\"master\\\", \\\"sonar.pullrequest.provider\\\" : \\\"GitHub\\\", \\\"sonar.pullrequest.github.repository\\\" : \\\"#{data[:repository][:slug]}\\\", \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'new pull request to long branch' do
    let(:job) { super().merge( {:pull_request => '123', :pull_request_head_branch => 'branch1' })}

    it { should_not include_sexp [:export, ['SONAR_GITHUB_TOKEN', 'mytoken' ]] }
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS',
      "\"{ \\\"sonar.pullrequest.key\\\" : \\\"123\\\", \\\"sonar.pullrequest.branch\\\" : \\\"branch1\\\", \\\"sonar.pullrequest.base\\\" : \\\"master\\\", \\\"sonar.pullrequest.provider\\\" : \\\"GitHub\\\", \\\"sonar.pullrequest.github.repository\\\" : \\\"#{data[:repository][:slug]}\\\", \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'deprecated pull request analysis' do
    let(:config) { { :github_token => 'mytoken' } }
    let(:job) { super().merge(:pull_request => '123')}

    it { should include_sexp [:export, ['SONAR_GITHUB_TOKEN', 'mytoken' ]] }
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS',
      "\"{ \\\"sonar.analysis.mode\\\" : \\\"preview\\\", \\\"sonar.github.repository\\\" : \\\"#{data[:repository][:slug]}\\\", \\\"sonar.github.pullRequest\\\" : \\\"123\\\", \\\"sonar.github.oauth\\\" : \\\"$SONAR_GITHUB_TOKEN\\\", \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'deprecated pull request analysis with env var from settings' do
    let(:data) { super().merge(:env_vars => ['name' => 'SONAR_GITHUB_TOKEN', 'value' => 'mytoken', 'public' => false])}
    let(:job) { super().merge(:pull_request => '123')}

    # it's already set in the env
    it { should_not include_sexp [:export, ['SONAR_GITHUB_TOKEN', 'mytoken' ]] }
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS',
      "\"{ \\\"sonar.analysis.mode\\\" : \\\"preview\\\", \\\"sonar.github.repository\\\" : \\\"#{data[:repository][:slug]}\\\", \\\"sonar.github.pullRequest\\\" : \\\"123\\\", \\\"sonar.github.oauth\\\" : \\\"$SONAR_GITHUB_TOKEN\\\", \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'deprecated pull request analysis with env var from yml' do
    let(:data) { super().merge(config: { :global_env => 'SONAR_GITHUB_TOKEN=mytoken' })}
    let(:job) { super().merge(:pull_request => '123')}

    # it's already set in the env
    it { should_not include_sexp [:export, ['SONAR_GITHUB_TOKEN', 'mytoken' ]] }
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS',
      "\"{ \\\"sonar.analysis.mode\\\" : \\\"preview\\\", \\\"sonar.github.repository\\\" : \\\"#{data[:repository][:slug]}\\\", \\\"sonar.github.pullRequest\\\" : \\\"123\\\", \\\"sonar.github.oauth\\\" : \\\"$SONAR_GITHUB_TOKEN\\\", \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'add organization' do
    let(:config) { { :organization => 'myorg' } }

    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS',
      "\"{ \\\"sonar.organization\\\" : \\\"myorg\\\", \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'branch analysis' do
    let(:config) { { :branches => ['branch2', 'branch*'] } }
    let(:job)    { { :branch => 'branch1' } }

    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.branch\\\" : \\\"branch1\\\", \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'new branch analysis' do
    let(:job)    { { :branch => 'branch1' } }

    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.branch.name\\\" : \\\"branch1\\\", \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'dont define branch if default branch' do
    let(:job)    { { :branch => 'branch1' } }
    let(:data)   {
      super()[:repository][:default_branch] = 'branch1'
      super()
    }

    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\" }\""]] }
  end

  describe 'skip branch' do
    let(:config) { { :branches => 'branch1' } }
    let(:job)    { { :branch => 'branch2' } }

    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.scanner.skip\\\" : \\\"true\\\" }\""]] }
    it { should include_sexp [:export, ['SONARQUBE_SKIPPED', "true"], {:echo=>true}] }
  end

  describe 'define login with env' do
    let(:data) { super().merge(:env_vars => ['name' => 'SONAR_TOKEN', 'value' => 'mytoken', 'public' => false])}
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.host.url\\\" : \\\"https://sonarcloud.io\\\", \\\"sonar.login\\\" : \\\"$SONAR_TOKEN\\\" }\""]] }
  end
end
