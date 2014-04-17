shared_examples_for 'a jvm build' do
  it_behaves_like 'a jdk build'

  describe 'if build.gradle exists' do
    before :each do
      file('build.gradle')
    end

    context 'without a gradle wrapper' do
      it 'installs with gradle assemble' do
        is_expected.to run 'gradle assemble', echo: true, log: true, assert: true, timeout: timeout_for(:install)
      end

      it 'runs gradle check' do
        is_expected.to run 'gradle check', echo: true, log: true, timeout: timeout_for(:script)
      end
    end

    context 'with a gradle wrapper present' do
      before do
        executable('./gradlew')
      end

      it 'installs with ./gradlew assemble' do
        is_expected.to run './gradlew assemble', echo: true, log: true, assert: true, timeout: timeout_for(:install)
      end

      it 'runs ./gradlew check' do
        is_expected.to run './gradlew check', echo: true, log: true, timeout: timeout_for(:script)
      end
    end
  end

  describe 'if pom.xml exists' do
    before :each do
      file('pom.xml')
    end

    it 'installs with mvn install -DskipTests=true -B' do
      is_expected.to run 'mvn install -DskipTests=true -B', echo: true, log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs mvn test -B' do
      is_expected.to run 'mvn test -B', echo: true, log: true, timeout: timeout_for(:script)
    end
  end

  describe 'if neither gradle nor mvn are used' do
    it 'runs ant test' do
      is_expected.to run 'ant test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end
end
