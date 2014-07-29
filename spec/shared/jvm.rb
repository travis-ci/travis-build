shared_examples_for 'a jvm build' do
  it_behaves_like 'a jdk build'

  describe 'if build.gradle exists' do
    before :each do
      file('build.gradle')
    end

    context 'without a gradle wrapper' do
      it 'installs with gradle assemble' do
        is_expected.to travis_cmd 'gradle assemble', echo: true, timing: true, assert: true, retry: true
      end

      it 'runs gradle check' do
        is_expected.to travis_cmd 'gradle check', echo: true, timing: true
      end
    end

    context 'with a gradle wrapper present' do
      before do
        executable('./gradlew')
      end

      it 'installs with ./gradlew assemble' do
        is_expected.to travis_cmd './gradlew assemble', echo: true, timing: true, assert: true, retry: true
      end

      it 'runs ./gradlew check' do
        is_expected.to travis_cmd './gradlew check', echo: true, timing: true
      end
    end
  end

  describe 'if pom.xml exists' do
    before :each do
      file('pom.xml')
    end

    it 'installs with mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V' do
      is_expected.to travis_cmd 'mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V', echo: true, assert: true
    end

    it 'runs mvn test -B' do
      is_expected.to travis_cmd 'mvn test -B', echo: true, timing: true
    end
  end

  describe 'if neither gradle nor mvn are used' do
    it 'runs ant test' do
      is_expected.to travis_cmd 'ant test', echo: true, timing: true
    end
  end

end
