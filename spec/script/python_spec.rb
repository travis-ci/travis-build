require 'spec_helper'

describe Travis::Build::Script::Python do
  let(:data) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data).compile }

  describe 'given a script' do
    before :each do
      data['config']['script'] = 'script'
    end

    it_behaves_like 'a build script'
  end

  it 'sets TRAVIS_PYTHON_VERSION' do
    should set 'TRAVIS_PYTHON_VERSION', '2.7'
  end

  it 'sets up the python version (pypy)' do
    data['config']['python'] = 'pypy'
    should run 'echo $ source ~/virtualenv/pypy/bin/activate' # TODO can't really capture source, yet
  end

  it 'sets up the python version (2.7)' do
    should run 'echo $ source ~/virtualenv/python2.7/bin/activate' # TODO can't really capture source, yet
  end

  it 'announces python --version' do
    should announce 'python --version'
  end

  it 'announces pip --version' do
    should announce 'pip --version'
  end

  describe 'if no requirements file exists' do
    # it 'installs with ' do
    #   should run '', echo: true, assert: true, log: true, timeout: timeout_for(:install)
    # end
  end

  describe 'if Requirements.txt exists' do
    before(:each) do
      file('Requirements.txt')
    end

    it 'installs with pip' do
      should install 'pip install -r Requirements.txt --use-mirrors'
    end
  end

  describe 'if requirements.txt exists' do
    before(:each) do
      file('requirements.txt')
    end

    # TODO [[ -f file ]] matches case insensitive on mac osx but doesn't on ubuntu?
    xit 'installs with pip' do
      should install 'pip install -r requirements.txt --use-mirrors'
    end
  end
end
