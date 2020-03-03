require 'spec_helper'

describe Travis::Build::Git, :sexp do
  let(:netrc_inst)  { /echo -e "machine #{host}\\n  login travis-ci\\n  password access_token\\n" > \${TRAVIS_HOME}\/\.netrc/ }
  let(:netrc_oauth) { /echo -e "machine #{host}\\n  login oauth_token\\n" > \${TRAVIS_HOME}\/\.netrc/ }
  let(:host)        { 'github.com' }
  let(:payload)     { payload_for(:push, :ruby) }
  let(:script)      { Travis::Build::Script.new(payload) }
  subject           { script.sexp }

  before { Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token' }

  shared_examples 'writes a netrc' do |type|
    it 'writes ${TRAVIS_HOME}/.netrc' do
      sexp_find(subject, [:raw, send(:"netrc_#{type}"), assert: true])
    end
  end

  shared_examples 'does not write a netrc' do
    it 'does not write ${TRAVIS_HOME}/.netrc' do
      should_not include_sexp [:raw, netrc_inst, assert: true]
      should_not include_sexp [:raw, netrc_oauth, assert: true]
    end
  end

  shared_examples 'installs an ssh key' do
    it 'installs an ssh key' do
      should include_sexp [:file, ['~/.ssh/id_rsa', 'key']]
    end
  end

  shared_examples 'does not install an ssh key' do
    it 'does not install an ssh key' do
      should_not include_sexp [:file, ['~/.ssh/id_rsa', 'key']]
    end
  end

  shared_examples 'clones via' do |protocol|
    let(:ssh)   { "git@github.com:#{payload[:repository][:slug]}.git" }
    let(:https) { "https://github.com/#{payload[:repository][:slug]}.git" }
    let(:cmd)   { [:cmd, /git clone.* #{send(protocol)}/] }

    it "clones via #{protocol}" do
      expect(sexp_find(subject, cmd)).to_not match_array([])
    end
  end

  shared_examples 'does not clone' do
    let(:payload) {payload_for(:push, :ruby, git: { clone: 'false'})}

    it 'clones via ssh' do
      expect(sexp_find(subject, cmd)).to be_nil
    end
  end

  # Behaviour:
  #
  # * private repo without installation: install key and use ssh clone
  # * private repo with installation with custom key: install custom key, ssh clone
  # * private repo with installation and no custom key: install default key, write netrc, https clone
  # * enterprise with config.prefer_https: install default key, write netrc, https clone
  # * public repo: no ssh key, no netrc https clone

  describe 'private repo without an installation' do
    before { payload[:repository][:private] = true }
    before { payload[:ssh_key] = { source: 'default_repository_key', value: 'key' } }

    include_examples 'installs an ssh key'
    include_examples 'does not write a netrc'
    include_examples 'clones via', :ssh
  end

  describe 'private repo with an installation and custom key' do
    before { payload[:repository][:private] = true }
    before { payload[:repository][:installation_id] = 1 }
    before { payload[:ssh_key] = { source: 'repository_settings', value: 'key' } }

    include_examples 'installs an ssh key'
    include_examples 'does not write a netrc'
    include_examples 'clones via', :ssh
  end

  describe 'private repo with an installation and no custom key' do
    before { payload[:repository][:private] = true }
    before { payload[:repository][:installation_id] = 1 }
    before { payload[:ssh_key] = { source: 'default_repository_key', value: 'key' } }

    include_examples 'installs an ssh key'
    include_examples 'writes a netrc', :inst
    include_examples 'clones via', :https
  end

  describe 'config.prefer_https' do
    let(:host) { 'github.enterprise.com' }

    before { payload[:prefer_https] = true }
    before { payload[:ssh_key] = { source: 'default_repository_key', value: 'key' } }
    before { payload[:oauth_token] = 'oauth_token' }

    include_examples 'installs an ssh key'
    include_examples 'writes a netrc', :oauth
    include_examples 'clones via', :https
  end

  describe 'public repo' do
    before { payload[:repository][:private] = false }

    include_examples 'does not install an ssh key'
    include_examples 'does not write a netrc'
    include_examples 'clones via', :https
  end
end
