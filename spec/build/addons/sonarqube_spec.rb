require 'spec_helper'

describe Travis::Build::Addons::Sonarqube, :sexp do
  let(:script) { stub('script') }
  let(:config) { :true }
  let(:job)    { { :branch => 'master' } }
  let(:data)   { payload_for(:push, :ruby, job: job, config: { addons: { sonarqube: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_before_script }

  it_behaves_like 'compiled script' do
    let(:code) { ['curl -sSLo $HOME/.sonarscanner/sonar-scanner.zip http://repo1.maven.org/maven2/org/sonarsource/scanner/cli/sonar-scanner-cli/2.8/sonar-scanner-cli-2.8.zip'] }
  end

  describe 'scanner installation' do
    it { should include_sexp [:export, ['SONAR_SCANNER_HOME', '$HOME/.sonarscanner/sonar-scanner-2.8'], {:echo=>true}] }
    it { should include_sexp [:export, ['PATH', "\"$PATH:$HOME/.sonarscanner/sonar-scanner-2.8/bin\""]] }
  end
  
  describe 'skip pull request analysis' do
    let(:job) { super().merge( :pull_request => '123' )}
    
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.scanner.skip\\\" : \\\"true\\\" }\""]] }
    it { should include_sexp [:export, ['SONARQUBE_SKIPPED', "true"], {:echo=>true}] }
    
  end
  
    describe 'pull request analysis' do
    let(:config) { { :github_token => 'mytoken' } }
    let(:job) { super().merge(:pull_request => '123')}
    
    it { should include_sexp [:export, ['SONAR_GITHUB_TOKEN', 'mytoken' ]] }
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', 
      "\"{ \\\"sonar.analysis.mode\\\" : \\\"preview\\\", \\\"sonar.github.repository\\\" : \\\"travis-ci/travis-ci\\\", \\\"sonar.github.pullRequest\\\" : \\\"123\\\", \\\"sonar.github.oauth\\\" : \\\"$SONAR_GITHUB_TOKEN\\\", \\\"sonar.host.url\\\" : \\\"https://sonarqube.com\\\" }\""]] }
    
  end
  
  describe 'branch analysis' do
    let(:config) { { :branches => ['branch2', 'branch*'] } }
    let(:job)    { { :branch => 'branch1' } }
    
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.branch\\\" : \\\"branch1\\\", \\\"sonar.host.url\\\" : \\\"https://sonarqube.com\\\" }\""]] }
  end
  
  describe 'skip branch' do
    let(:config) { { :branches => 'branch1' } }
    let(:job)    { { :branch => 'branch2' } }
    
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.scanner.skip\\\" : \\\"true\\\" }\""]] }
    it { should include_sexp [:export, ['SONARQUBE_SKIPPED', "true"], {:echo=>true}] }
  end
  
  describe 'define login with env' do
    let(:config) { { :env => { :SONAR_TOKEN => 'mytoken' } } }
    
    it { should include_sexp [:export, ['SONARQUBE_SCANNER_PARAMS', "\"{ \\\"sonar.host.url\\\" : \\\"https://sonarqube.com\\\", \\\"sonar.login\\\" : \\\"$SONAR_TOKEN\\\" }\""]] }
  end
end
