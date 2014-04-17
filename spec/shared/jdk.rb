shared_examples_for 'a jdk build' do
  describe 'if no jdk is given' do
    before :each do
      data['config']['jdk'] = nil
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
      is_expected.to run 'jdk_switcher use openjdk7', log: true, assert: true
    end
  end

  it 'runs java -version' do
    is_expected.to run 'java -version', echo: true, log: true
  end

  it 'runs javac -version' do
    is_expected.to run 'javac -version', echo: true, log: true
  end
end

