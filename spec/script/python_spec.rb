require 'spec_helper'

describe Travis::Build::Script::Python do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  describe 'given a script' do
    before :each do
      data['config']['script'] = 'script'
    end

    it_behaves_like 'a build script'
  end

  it 'sets TRAVIS_PYTHON_VERSION' do
    is_expected.to set 'TRAVIS_PYTHON_VERSION', '2.7'
  end

  it 'sets up the python version (pypy)' do
    data['config']['python'] = 'pypy'
    is_expected.to travis_cmd 'source ~/virtualenv/pypy/bin/activate', echo: true, timing: true, assert: true
    store_example 'pypy'
  end

  it 'sets up the python version (pypy3)' do
    data['config']['python'] = 'pypy3'
    is_expected.to travis_cmd 'source ~/virtualenv/pypy3/bin/activate', echo: true, timing: true, assert: true
    store_example 'pypy3'
  end

  it 'sets up the python version (2.7)' do
    is_expected.to travis_cmd 'source ~/virtualenv/python2.7/bin/activate', echo: true, timing: true, assert: true
    store_example '2.7'
  end

  it 'announces python --version' do
    is_expected.to announce 'python --version'
  end

  it 'announces pip --version' do
    is_expected.to announce 'pip --version'
  end

  describe 'if no requirements file exists' do
    # it 'installs with ' do
    #   should run '', echo: true, assert: true
    # end
  end

  describe 'if Requirements.txt exists' do
    before(:each) do
      file('Requirements.txt')
    end

    it 'installs with pip' do
      is_expected.to travis_cmd 'pip install -r Requirements.txt', echo: true, timing: true, assert: true, retry: true
    end
  end

  unless `uname -a`.include?('Darwin')
    describe 'if requirements.txt exists' do
      before(:each) do
        file('requirements.txt')
      end

      it 'installs with pip' do
        is_expected.to travis_cmd 'pip install -r requirements.txt', echo: true, timing: true, assert: true, retry: true
      end
    end
  end

  describe 'system site packages should be used' do
    before(:each) do
      data['config']['virtualenv'] = { 'system_site_packages' => true }
    end

    it 'sets up python with system site packages enabled' do
      is_expected.to travis_cmd "source ~/virtualenv/python2.7_with_system_site_packages/bin/activate", echo: true, timing: true, assert: true
    end
  end
end
