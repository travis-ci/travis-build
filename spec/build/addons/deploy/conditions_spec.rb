require 'spec_helper'

describe Travis::Build::Addons::Deploy::Conditions do
  let(:data)       { payload_for(:push) }
  let(:config)     { {} }
  let(:conditions) { described_class.new(Travis::Build::Addons::Deploy::Config.new(data, config)) }

  describe 'to_s' do
    subject { conditions.to_s }
    it { should eql('(-z $TRAVIS_PULL_REQUEST) && ($TRAVIS_BRANCH = master)') }
  end

  describe 'all' do
    subject { conditions.send(:all) }

    describe 'with an empty config' do
      it { expect(subject.keys).to eql([:is_pull_request, :matches_branch]) }
      it { should include is_pull_request: '(-z $TRAVIS_PULL_REQUEST)' }
      it { should include matches_branch: '($TRAVIS_BRANCH = master)' }
    end

    describe 'repo' do
      describe 'on: :repo set' do
        let (:config) { { on: { repo: 'someone/travis-ci' } } }
        it { should include matches_repo: '($TRAVIS_REPO_SLUG = someone/travis-ci)' }
      end
    end

    describe 'branches' do
      describe 'on: :all_branches set' do
        let (:config) { { on: { all_branches: true } } }
        it { should_not include matches_branch: '($TRAVIS_BRANCH = master)' }
      end

      describe 'on: :branches set to a String' do
        let (:config) { { on: { branch: 'production' } } }
        it { should include matches_branch: '($TRAVIS_BRANCH = production)' }
      end

      describe 'on: :branches set to an Array' do
        let (:config) { { on: { branch: ['staging', 'production'] } } }
        it { should include matches_branch: '($TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production)' }
      end
    end

    describe 'tags' do
      describe 'on: :tags set to true' do
        let (:config) { { on: { tags: true } } }
        it { should include is_tag: '(-n $TRAVIS_TAG)' }
      end

      describe 'on: :tags set to false' do
        let (:config) { { on: { tags: false } } }
        it { should include is_not_tag: '(-z $TRAVIS_TAG)' }
      end
    end

    describe 'runtimes' do
      describe 'on: :ruby set to 2.1.1' do
        let (:config) { { on: { ruby: '2.1.1' } } }
        it { should include matches_runtime: '($TRAVIS_RUBY_VERSION = 2.1.1)' }
      end
    end

    describe 'custom' do
      describe 'on: :condition set to a String' do
        let (:config) { { on: { condition: '$FOO = foo' } } }
        it { should include custom: '($FOO = foo)' }
      end

      describe 'on: :condition set to an Array' do
        let(:config) { { on: { condition: ['$FOO = foo', '$BAR = bar'] } } }
        it { should include custom: '(($FOO = foo) && ($BAR = bar))' }
      end
    end
  end

  describe 'all with negate: true' do
    let (:config) { { on: { branch: ['staging', 'production'], condition: ['$FOO = foo', '$BAR = bar'] } } }
    subject { conditions.send(:all, negate: true) }

    it { should include is_pull_request: '(! (-z $TRAVIS_PULL_REQUEST))' }
    it { should include custom: '(! (($FOO = foo) && ($BAR = bar)))' }
    it { should include matches_branch: '(! ($TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production))' }
  end
end
