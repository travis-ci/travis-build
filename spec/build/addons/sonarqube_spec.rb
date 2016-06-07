require 'spec_helper'

describe Travis::Build::Addons::Sonarqube, :sexp do
  let(:script) { stub('script') }
  let(:config) { :true }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { sonarqube: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_before_script }

  it_behaves_like 'compiled script' do
    let(:code) { ['curl -sSLo $HOME/.sonarscanner/sonar-scanner.zip', 'echo "export MAVEN_OPTS=\"\$MAVEN_OPTS -Dsonar.host.url=https://nemo.sonarqube.org\"" >> ~/.mavenrc'] }
  end

  describe 'scanner installation' do
    it { should include_sexp [:export, ['SONAR_SCANNER_HOME', '$HOME/.sonarscanner/sonar-scanner-2.6.1'], {:echo=>true}] }
    it { should include_sexp [:export, ['SONAR_SCANNER_OPTS', "\"$SONAR_SCANNER_OPTS -Dsonar.host.url=https://nemo.sonarqube.org\""], {:echo=>true}] }
    it { should include_sexp [:export, ['GRADLE_OPTS', "\"$GRADLE_OPTS -Dsonar.host.url=https://nemo.sonarqube.org\""], {:echo=>true}] }
    it { should include_sexp [:export, ['PATH', "\"$PATH:$HOME/.sonarscanner/sonar-scanner-2.6.1/bin\""]] }
  end
end

