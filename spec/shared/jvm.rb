shared_examples_for 'a jvm build' do
  it_behaves_like 'a jdk build'

  describe 'if build.gradle exists' do
    before :each do
      file('build.gradle')
    end

    context 'without a gradle wrapper' do
      it 'installs with gradle assemble' do
        should run 'gradle assemble', echo: true, log: true, assert: true, timeout: timeout_for(:install)
      end

      it 'runs gradle check' do
        should run 'gradle check', echo: true, log: true, timeout: timeout_for(:script)
      end
    end

    context 'with a gradle wrapper present' do
      before do
        executable('./gradlew')
      end

      it 'installs with ./gradlew assemble' do
        should run './gradlew assemble', echo: true, log: true, assert: true, timeout: timeout_for(:install)
      end

      it 'runs ./gradlew check' do
        should run './gradlew check', echo: true, log: true, timeout: timeout_for(:script)
      end
    end
  end

  describe 'if pom.xml exists' do
    before :each do
      file('pom.xml')
    end

    it 'installs with mvn install -DskipTests=true -B' do
      should run 'mvn install -DskipTests=true -B', echo: true, log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs mvn test -B' do
      should run 'mvn test -B', echo: true, log: true, timeout: timeout_for(:script)
    end
  end

  describe 'if neither gradle nor mvn are used' do
    it 'runs ant test' do
      should run 'ant test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end
end
