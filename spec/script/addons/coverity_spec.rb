require 'spec_helper'

describe Travis::Build::Script::Addons::Coverity do
  let(:script) { stub_everything('script') }

  before(:each) { 
    script.stubs(:fold).yields(script) 
    described_class.any_instance.stubs(:platform).returns('linux64')
  }

  let(:config) { 
    {
      build_utility_version: '6.6.1',
      project: {
        name: 'theProject',
        version: '1.0',
        description: 'Travis-CI Build',
      },
      email: 'nobody@example.com'
    } 
  }

  subject { described_class.new(script, config) }

  describe 'download_build_utility' do
    it 'is correct' do
      exp = <<BASH
set -e
echo -e "\033[33;1mLooking for /usr/local/cov-analysis/cov-analysis-linux64-6.6.1...\033[0m"
if [ -d /usr/local/cov-analysis/cov-analysis-linux64-6.6.1 ]
then
echo -e "\033[33;1mUsing existing Coverity Build Utility v6.6.1\033[0m"
else
echo -e "\033[33;1mDownloading Coverity Build Utility v6.6.1\033[0m"
sudo mkdir -p /usr/local/cov-analysis
sudo chown -R travis /usr/local/cov-analysis
echo wget -O /tmp/cov-analysis.tar.gz https://scan.coverity.com/build_tool/cov-analysis-linux64-6.6.1.tar.gz
pushd /usr/local/cov-analysis
tar xf /tmp/cov-analysis.tar.gz
popd
fi
BASH
      subject.download_build_utility.should == exp
    end
  end

  describe 'build_command' do
    it 'is correct' do
      exp = <<BASH
COVERITY_UNSUPPORTED=1 PATH=/usr/local/cov-analysis/cov-analysis-linux64-6.6.1/bin:${PATH} cov-build --dir cov-int make -j8
tar czf cov-int.tgz cov-int
BASH
      subject.build_command.should == exp
    end
  end

  describe 'submit_results' do
    it 'is correct' do
      exp = <<BASH
curl -X POST -d 'email=nobody@example.com' -d 'project=theProject' -d 'version=1.0' -d 'description=Travis-CI Build' -d "token=$COVERITY_SCAN_TOKEN" -d 'file=@cov-int.tgz' http://scan5.coverity.com/cgi-bin/upload.py
BASH
      subject.submit_results.should == exp
    end
  end

  describe 'build_and_submit' do
    it 'is correct' do
      exp = <<BASH
set -e
COVERITY_UNSUPPORTED=1 PATH=/usr/local/cov-analysis/cov-analysis-linux64-6.6.1/bin:${PATH} cov-build --dir cov-int make -j8
tar czf cov-int.tgz cov-int
curl -X POST -d 'email=nobody@example.com' -d 'project=theProject' -d 'version=1.0' -d 'description=Travis-CI Build' -d "token=$COVERITY_SCAN_TOKEN" -d 'file=@cov-int.tgz' http://scan5.coverity.com/cgi-bin/upload.py
BASH
      subject.build_and_submit.should == exp
    end
  end

  describe 'install' do

    it 'runs the command' do
      script.expects(:fold).with('install_coverity').yields(script)
      script.expects(:cmd).with(subject.download_build_utility, assert: false, echo: false)
      subject.install
    end
  end

  describe 'script' do

    it 'runs the command' do
      script.expects(:fold).with('build_coverity').yields(script)
      script.expects(:cmd).with(subject.build_and_submit, assert: false, echo: false)
      subject.script
    end
  end

end
