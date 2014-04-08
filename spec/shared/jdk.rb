shared_examples_for 'a jdk build' do
  describe 'if no jdk is given' do
    before :each do
      data['config']['jdk'] = nil
    end

    it 'does not set TRAVIS_JDK_VERSION' do
      should_not set 'TRAVIS_JDK_VERSION'
    end

    it 'does not run jdk_switcher' do
      should_not run 'jdk_switcher'
    end
  end

  describe 'if jdk is given' do
    before :each do
      data['config']['jdk'] = 'openjdk7'
    end

    it 'sets TRAVIS_JDK_VERSION' do
      should set 'TRAVIS_JDK_VERSION', 'openjdk7'
    end

    it 'runs jdk_switcher' do
      should setup 'jdk_switcher use openjdk7'
    end
  end

  it 'runs java -version' do
    should announce 'java -version'
  end

  it 'runs javac -version' do
    should announce 'javac -version'
  end
end

