require 'spec_helper'

describe Travis::Build::Script::Addons::Deploy, :sexp do
  let(:config) { {} }
  let(:data)   { PAYLOADS[:push].deep_clone.merge(config: { before_deploy: './before_deploy', after_deploy: './after_deploy' }) }
  let(:script) { Travis::Build::Script.new(data) }
  let(:sh)     { script.sh }
  let(:addon)  { described_class.new(script, config) }
  subject      { addon.deploy && sh.to_sexp }

  let(:terminate_on_failure) { [:if, '$? -ne 0', [:then, [:cmds, [[:echo, 'Failed to deploy.', ansi: :red], [:cmd, 'travis_terminate 2']]]]] }

  describe 'deploys if conditions apply' do
    let(:config) { { provider: 'heroku', password: 'foo', email: 'user@host' } }
    let(:sexp)   { sexp_find(subject, [:if, '($TRAVIS_BRANCH = master)']) }

    it { expect(sexp).to include_sexp [:cmd, './before_deploy', assert: true, echo: true, timing: true] }
    it { expect(sexp).to include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do ruby -S gem install dpl', assert: true, timing: true] }
    it { expect(sexp).to include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do ruby -S dpl --provider="heroku" --password="foo" --email="user@host" --fold', assert: true, timing: true] }
    it { expect(sexp).to include_sexp terminate_on_failure }
    it { expect(sexp).to include_sexp [:cmd, './after_deploy', assert: true, echo: true, timing: true] }
  end

  describe 'implicit branches' do
    let(:data)   { super().merge(branch: 'staging') }
    let(:config) { { provider: 'heroku', app: { staging: 'foo', production: 'bar' } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production)'] }
  end

  describe 'on tags' do
    let(:config) { { provider: 'heroku', on: { tags: true } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ("$TRAVIS_TAG" != "")'] }
  end

  describe 'multiple providers' do
    let(:heroku)    { { provider: 'heroku', password: 'foo', email: 'user@host', on: { condition: '$ENV_1 = 1' } } }
    let(:nodejitsu) { { provider: 'nodejitsu', user: 'foo', api_key: 'bar', on: { condition: '$ENV_2 = 2' } } }
    let(:config)    { [heroku, nodejitsu] }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ($ENV_1 = 1)'] }
    it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do ruby -S dpl --provider="heroku" --password="foo" --email="user@host" --fold', assert: true, timing: true] }
    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ($ENV_2 = 2)'] }
    it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do ruby -S dpl --provider="nodejitsu" --user="foo" --api_key="bar" --fold', assert: true, timing: true] }
  end

  describe 'allow_failure' do
    let(:config) { { provider: 'heroku', password: 'foo', email: 'user@host', allow_failure: true } }

    it { should_not include_sexp terminate_on_failure }
  end

  describe 'multiple conditions match' do
    let(:config) { { provider: 'heroku', on: { condition: ['$ENV_1 = 1', '$ENV_2 = 2'] } } }
    before       { addon.deploy }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ($ENV_1 = 1) && ($ENV_2 = 2)'] }
  end

  let(:not_permitted)    { [:echo, 'Skipping deployment with the heroku provider because this branch is not permitted deploy.', ansi: :red] }
  let(:custom_condition) { [:echo, 'Skipping deployment with the heroku provider because a custom condition was not met.', ansi: :red] }
  let(:is_pull_request)  { [:echo, 'Skipping deployment with the heroku provider because the current build is a pull request.', ansi: :red] }

  describe 'deploy condition fails' do
    let(:config) { { provider: 'heroku', on: { condition: '$ENV_2 = 1'} } }
    let(:sexp)   { sexp_find(subject, [:if, '($TRAVIS_BRANCH = master) && ($ENV_2 = 1)'], [:else]) }

    it { expect(sexp_find(sexp, [:if, ' ! $TRAVIS_BRANCH = master'])).to include_sexp not_permitted }
    it { expect(sexp_find(sexp, [:if, ' ! $ENV_2 = 1'])).to include_sexp custom_condition }
  end

  describe 'build is a pull request' do
    let(:config) { { provider: 'heroku', password: 'foo', email: 'user@host' } }
    before       { script.data.stubs(pull_request: '123') }
    after        { store_example('pull_request') }

    it { should include_sexp is_pull_request }
  end
end

