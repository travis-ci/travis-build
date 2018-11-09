require 'spec_helper'

describe Travis::Build::Addons::Deploy, :sexp do
  # let(:stages)  { stub('stages', run_stage: true) }
  # let(:script)  { stub('script', stages: stages) }
  let(:script)  { Travis::Build::Script::Ruby.new(data) }
  let(:scripts) { { before_deploy: ['./before_deploy_1.sh', './before_deploy_2.sh'], after_deploy: ['./after_deploy_1.sh', './after_deploy_2.sh'] } }
  let(:config)  { {} }
  let(:os)      { 'linux' }
  let(:data)    { payload_for(:push, :ruby, paranoid: false, config: { os: os, addons: { deploy: config } }.merge(scripts)) }
  # let(:sh)      { Travis::Shell::Builder.new }
  let(:sh)      { script.sh }
  # let(:addon)   { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  # subject       { addon.after_after_success && sh.to_sexp }
  subject       { script.sexp }

  let(:terminate_on_failure) { [:if, '$? -ne 0', [:then, [:cmds, [[:echo, 'Failed to deploy.', ansi: :red], [:cmd, 'travis_terminate 2']]]]] }

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:cmds) { ['ruby -S gem install dpl', 'ruby -S dpl'] }
  end

  context "when after_success is also present" do
    let(:scripts) { { after_success: ["echo hello"], before_deploy: ['./before_deploy_1.sh', './before_deploy_2.sh'], after_deploy: ['./after_deploy_1.sh', './after_deploy_2.sh'] } }

    it { store_example(name: 'after success and deploy') }
  end

  describe 'deploys if conditions apply' do
    let(:config) { { provider: 'heroku', password: 'foo', email: 'user@host' } }
    let(:sexp)   { sexp_find(subject, [:if, '($TRAVIS_BRANCH = master)']) }

    it { expect(sexp).to include_sexp [:cmd, './before_deploy_1.sh', assert: true, echo: true, timing: true] }
    it { expect(sexp).to include_sexp [:cmd, './before_deploy_2.sh', assert: true, echo: true, timing: true] }
    it "installs dpl < 1.9 if travis_internal_ruby returns 1.9*" do
      expect(
        sexp_filter(
          sexp_filter(
            sexp,
            [:if, "$(rvm use $(travis_internal_ruby) do ruby -e \"puts RUBY_VERSION\") = 1.9*"]
          )[0],
          [:if, "-e $HOME/.rvm/scripts/rvm"]
        )[0]
      ).to include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do ruby -S gem install dpl -v '< 1.9' ", echo: true, assert: true, timing: true]
    end

    it "installs latest dpl if travis_internal_ruby does not return 1.9*" do
      expect(
        sexp_filter(
          sexp_filter(
            sexp,
            [:if, "$(rvm use $(travis_internal_ruby) do ruby -e \"puts RUBY_VERSION\") = 1.9*"]
          )[0],
          [:if, "-e $HOME/.rvm/scripts/rvm"]
        )[1]
      ).to include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do ruby -S gem install dpl", echo: true, assert: true, timing: true]
    end
    it { expect(sexp).to include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S gem install dpl', echo: true, assert: true, timing: true] }
    # it { expect(sexp).to include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S dpl --provider=heroku --password=foo --email=user@host --fold', assert: true, timing: true] }
    # it { expect(sexp).to include_sexp terminate_on_failure }
    it { expect(sexp).to include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do ruby -S dpl --provider=\"heroku\" --password=\"foo\" --email=\"user@host\" --fold; if [ $? -ne 0 ]; then echo \"failed to deploy\"; travis_terminate 2; fi", {:timing=>true}] }
    it { expect(sexp).to include_sexp [:cmd, './after_deploy_1.sh', echo: true, timing: true] }
    it { expect(sexp).to include_sexp [:cmd, './after_deploy_2.sh', echo: true, timing: true] }
  end

  describe 'branch specific option hashes (using :if)' do
    let(:data)   { super().merge(branch: 'staging') }
    let(:config) { { provider: 'heroku', if: { branch: { staging: 'foo', production: 'bar' } } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production)'] }
  end

  describe 'branch specific option hashes (using :on)' do
    let(:data)   { super().merge(branch: 'staging') }
    let(:config) { { provider: 'heroku', on: { branch: { staging: 'foo', production: 'bar' } } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production)'] }
  end

  describe 'option specific branch hashes (deprecated)' do
    let(:data)   { super().merge(branch: 'staging') }
    let(:config) { { provider: 'heroku', app: { staging: 'foo', production: 'bar' } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production)'] }
  end

  describe 'yields correct branch condition' do
    let(:data)   { super().merge(branch: 'foo') }
    let(:config) { { provider: 'engineyard', app: { foo: 'foo' } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = foo)'] }
    it { should_not match_sexp [:if, '($TRAVIS_BRANCH = not_foo)'] }
  end

  describe 'option specific Ruby version (using :if)' do
    let(:config) { { provider: 'heroku', if: { ruby: 'foo' } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ($TRAVIS_RUBY_VERSION = foo)'] }
  end

  describe 'option specific Ruby version (using :on)' do
    let(:config) { { provider: 'heroku', on: { ruby: 'foo' } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ($TRAVIS_RUBY_VERSION = foo)'] }
  end

  describe 'option specific Rust version' do
    let(:data)   { super().merge(language: 'rust') }
    let(:config) { { provider: 'heroku', on: { rust: 'stable', branch: 'bar' } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = bar) && ($TRAVIS_RUST_VERSION = stable)'] }
  end

  context 'when edge dpl is tested' do
    let(:data)   { super().merge(branch: 'staging') }
    let(:config) { { provider: 'heroku', edge: { source: 'svenvfuchs/dpl', branch: 'foo' } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master)'] }
    it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S gem uninstall -aIx dpl', echo: true] }
    it { store_example(name: 'edge') }
  end

  context 'when a mix of edge and release dpl are tested' do
    let(:data)   { super().merge(branch: 'staging') }
    let(:config) { { provider: 'heroku', edge: { source: 'svenvfuchs/dpl', branch: 'foo' } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master)'] }
    it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S gem uninstall -aIx dpl', echo: true] }
    it { store_example(name: 'edge') }
  end

  describe 'on tags' do
    let(:config) { { provider: 'heroku', on: { tags: true } } }

    it { should match_sexp [:if, '("$TRAVIS_TAG" != "")'] }
  end

  describe 'multiple providers' do
    let(:heroku)    { { provider: 'heroku', password: 'foo', email: 'user@host', on: { condition: '$FOO = foo' } } }
    let(:nodejitsu) { { provider: 'nodejitsu', user: 'foo', api_key: 'bar', on: { condition: '$BAR = bar' } } }
    let(:config)    { [heroku, nodejitsu] }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ($FOO = foo)'] }
    # it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S dpl --provider=heroku --password=foo --email=user@host --fold', assert: true, timing: true] }
    it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S dpl --provider="heroku" --password="foo" --email="user@host" --fold; if [ $? -ne 0 ]; then echo "failed to deploy"; travis_terminate 2; fi', timing: true] }
    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ($BAR = bar)'] }
    # it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S dpl --provider=nodejitsu --user=foo --api_key=bar --fold', assert: true, timing: true] }
    it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S dpl --provider="nodejitsu" --user="foo" --api_key="bar" --fold; if [ $? -ne 0 ]; then echo "failed to deploy"; travis_terminate 2; fi', timing: true] }
    it { should_not include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S gem uninstall -aIx dpl', echo: true] }
    it { store_example(name: 'multiple providers') }

    context 'when dpl switches from release to edge' do
      let(:heroku)    { { provider: 'heroku', password: 'foo', email: 'user@host', on: { condition: '$FOO = foo' } } }
      let(:nodejitsu) { { provider: 'nodejitsu', user: 'foo', api_key: 'bar', on: { condition: '$BAR = bar' }, edge: true } }
      let(:config)    { [heroku, nodejitsu] }

      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S gem uninstall -aIx dpl', echo: true] }
    end

    context 'when dpl switches from edge to release' do
      let(:heroku)    { { provider: 'heroku', password: 'foo', email: 'user@host', on: { condition: '$FOO = foo' } } }
      let(:nodejitsu) { { provider: 'nodejitsu', user: 'foo', api_key: 'bar', on: { condition: '$BAR = bar' }, edge: true } }
      let(:config)    { [nodejitsu, heroku] }

      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S gem uninstall -aIx dpl', echo: true] }
    end

    context 'when multiple dpl edge releases use the identical edge definitions' do
      let(:heroku)    { { provider: 'heroku', password: 'foo', email: 'user@host', on: { condition: '$FOO = foo' }, edge: true } }
      let(:nodejitsu) { { provider: 'nodejitsu', user: 'foo', api_key: 'bar', on: { condition: '$BAR = bar' }, edge: true } }
      let(:config)    { [nodejitsu, heroku] }
      let(:second_deploy) { sexp_find(subject, [:fold, "dpl_1"]) }

      it { expect(second_deploy).to_not include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S gem uninstall -aIx dpl', echo: true] }
      it { store_example(name: 'identical edges') }
    end

    context 'when edge dpl definitions change' do
      let(:heroku)    { { provider: 'heroku', password: 'foo', email: 'user@host', on: { condition: '$FOO = foo' }, edge: {branch: 'feature'} } }
      let(:nodejitsu) { { provider: 'nodejitsu', user: 'foo', api_key: 'bar', on: { condition: '$BAR = bar' }, edge: true } }
      let(:config)    { [nodejitsu, heroku] }
      let(:second_deploy) { sexp_find(subject, [:fold, "dpl_1"]) }

      it { expect(second_deploy).to include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do ruby -S gem uninstall -aIx dpl', echo: true] }
    end
  end

  describe 'allow_failure' do
    let(:config) { { provider: 'heroku', password: 'foo', email: 'user@host', allow_failure: true } }

    it { should_not include_sexp terminate_on_failure }
  end

  describe 'multiple conditions match' do
    let(:config) { { provider: 'heroku', on: { condition: ['$FOO = foo', '$BAR = bar'] } } }

    it { should match_sexp [:if, '($TRAVIS_BRANCH = master) && ($FOO = foo) && ($BAR = bar)'] }
  end

  describe 'deploy condition fails' do
    let(:config) { { provider: 'heroku', on: { condition: '$FOO = foo'} } }
    # let(:sexp)   { sexp_find(subject, [:if, '(-z $TRAVIS_PULL_REQUEST) && ($TRAVIS_BRANCH = master) && ($FOO = foo)'], [:else]) }
    let(:sexp)   { sexp_filter(subject, [:if, '($TRAVIS_BRANCH = master) && ($FOO = foo)'], [:else])[1] }

    let(:is_pull_request)  { [:echo, 'Skipping a deployment with the heroku provider because the current build is a pull request.', ansi: :yellow] }
    let(:not_permitted)    { [:echo, 'Skipping a deployment with the heroku provider because this branch is not permitted: master', ansi: :yellow] }
    let(:custom_condition) { [:echo, 'Skipping a deployment with the heroku provider because a custom condition was not met', ansi: :yellow] }

    # it { p subject; p sexp; expect(sexp_find(sexp, [:if, '(! (-z $TRAVIS_PULL_REQUEST))'])).to include_sexp is_pull_request }
    # it { expect(sexp_find(sexp, [:if, '(! ($TRAVIS_BRANCH = master))'])).to include_sexp not_permitted }
    # it { expect(sexp_find(sexp, [:if, '(! ($FOO = foo))'])).to include_sexp custom_condition }
    it { expect(sexp_find(sexp, [:if, ' ! ($TRAVIS_BRANCH = master)'])).to include_sexp not_permitted }
    it { expect(sexp_find(sexp, [:if, ' ! ($FOO = foo)'])).to include_sexp custom_condition }
    it { store_example(name: 'custom condition fails') }
  end

  describe 'deploy with compound condition fails' do
    let(:config) { { provider: 'heroku', on: { condition: '$FOO = foo && $BAR = bar'} } }
    let(:sexp)   { sexp_filter(subject, [:if, '($TRAVIS_BRANCH = master) && ($FOO = foo && $BAR = bar)'], [:else])[1] }

    let(:custom_condition) { [:echo, 'Skipping a deployment with the heroku provider because a custom condition was not met', ansi: :yellow] }

    it { expect(sexp_find(sexp, [:if, ' ! ($FOO = foo && $BAR = bar)'])).to include_sexp custom_condition }
  end

  describe 'deploy condition fails with tags' do
    let(:config) { { provider: 'heroku', on: { tags: true} } }
    let(:sexp)   { sexp_find(subject, [:if, '("$TRAVIS_TAG" != "")']) }

    let(:not_tag) { [:echo, "Skipping a deployment with the heroku provider because this is not a tagged commit", ansi: :yellow] }

    it { expect(sexp_find(sexp, [:if, ' ! ("$TRAVIS_TAG" != "")'])).to include_sexp not_tag }
  end

  context "when deploy.on is an array" do
    let(:config) { { provider: 'heroku', on: ["master", "dev"] } }
    it "should raise DeployConfigError" do
      expect { subject}.to raise_error(Travis::Build::DeployConfigError)
    end
  end
end
