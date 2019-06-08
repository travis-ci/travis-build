shared_examples_for 'a jdk build sexp' do
  let(:export_jdk_version) { [:export, ['TRAVIS_JDK_VERSION', 'openjdk7']] }
  let(:sexp)               { [:if, '"$(command -v jdk_switcher &>/dev/null; echo $?)" == 0'] }
  let(:run_jdk_switcher)   { [:cmd, 'jdk_switcher use openjdk7', assert: true, echo: true] }
  let(:set_dumb_term)      { [:export, ['TERM', 'dumb'], echo: true] }

  before do
    Travis::Build.config.app_host = 'build.travis-ci.org'
  end

  describe 'if no jdk is given' do
    before :each do
      data[:config][:jdk] = nil
    end

    # TODO not true, the code clearly says the opposite
    # it 'does not set TERM' do
    #   should_not include_sexp set_dumb_term
    # end

    it 'does not set TRAVIS_JDK_VERSION' do
      should_not include_sexp export_jdk_version
    end

    it 'does not run jdk_switcher' do
      should_not include_sexp run_jdk_switcher
    end
  end

  context "when jdk is an array" do
    before :each do
      data[:config][:jdk] = ['openjdk7']
    end

    it 'sets TRAVIS_JDK_VERSION' do
      should include_sexp export_jdk_version
    end
  end

  describe 'if build.gradle exists' do
    let(:sexp) { sexp_find(subject, [:if, '-f build.gradle || -f build.gradle.kts'], [:then]) }

    it "sets TERM to 'dumb'" do
      expect(sexp).to include_sexp set_dumb_term
    end
  end
end

shared_examples_for 'announces java versions' do
  it 'runs java -version' do
    should include_sexp [:cmd, 'java -Xmx32m -version', echo: true]
  end

  it 'runs javac -version' do
    should include_sexp [:cmd, 'javac -J-Xmx32m -version', echo: true]
  end
end
