shared_examples_for 'a jdk build' do
  describe 'if no jdk is given' do
    before :each do
      data['config']['jdk'] = nil
    end

    it 'does not set TERM' do
      is_expected.not_to set 'TERM'
    end

    it 'does not set TRAVIS_JDK_VERSION' do
      is_expected.not_to set 'TRAVIS_JDK_VERSION'
    end

    it 'does not run jdk_switcher' do
      is_expected.not_to run 'jdk_switcher'
    end
  end

  describe 'if jdk is given' do
    before :each do
      data['config']['jdk'] = 'openjdk7'
    end

    it 'sets TRAVIS_JDK_VERSION' do
      is_expected.to set 'TRAVIS_JDK_VERSION', 'openjdk7'
    end

    it 'runs jdk_switcher' do
      is_expected.to setup 'jdk_switcher use openjdk7'
    end
  end

  it 'runs java -version' do
    is_expected.to announce 'java -version'
  end

  it 'runs javac -version' do
    is_expected.to announce 'javac -version'
  end

  describe 'if build.gradle exists' do
    before :each do
      file('build.gradle')
    end

    it "sets TERM to 'dumb'" do
      is_expected.to set 'TERM', 'dumb'
    end
  end
end

