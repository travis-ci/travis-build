shared_examples_for 'a jvm build sexp' do
  it_behaves_like 'a jdk build sexp'

  describe 'install' do
    let(:options) { { assert: true, echo: true, retry: true, timing: true } }
    let(:sexp)    { sexp_find(subject, [:if, '-f gradlew']) }

    it 'runs `./gradlew assemble` if gradlew exists' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp([:cmd, './gradlew assemble', options])
    end

    it 'runs `gradle assemble` if build.gradle exists' do
      branch = sexp_find(sexp, [:elif, '-f build.gradle'])
      expect(branch).to include_sexp([:cmd, 'gradle assemble', options])
    end

    it 'runs `./mvnw install` if mvnw exists' do
      branch = sexp_find(sexp, [:elif, '-f mvnw'])
      expect(branch).to include_sexp([:cmd, './mvnw install -DskipTests=true -Dmaven.javadoc.skip=true -B -V', options])
    end

    it 'runs `mvn install` if pom.xml exists' do
      branch = sexp_find(sexp, [:elif, '-f pom.xml'])
      expect(branch).to include_sexp([:cmd, 'mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V', options])
    end
  end

  describe 'script' do
    let(:options) { { echo: true, timing: true } }
    let(:sexp)    { sexp_filter(subject, [:if, '-f gradlew'])[1] }

    it 'runs `./gradlew check` if gradlew exists' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp([:cmd, './gradlew check', options])
    end

    it 'runs `gradle check` if build.gradle exists' do
      branch = sexp_find(sexp, [:elif, '-f build.gradle'])
      expect(branch).to include_sexp([:cmd, 'gradle check', options])
    end

    it 'runs `./mvnw test` if mvnw exists' do
      branch = sexp_find(sexp, [:elif, '-f mvnw'])
      expect(branch).to include_sexp([:cmd, './mvnw test -B', options])
    end

    it 'runs `mvn test` if pom.xml exists' do
      branch = sexp_find(sexp, [:elif, '-f pom.xml'])
      expect(branch).to include_sexp([:cmd, 'mvn test -B', options])
    end

    it 'runs `ant test` otherwise' do
      branch = sexp_find(sexp, [:else])
      expect(branch).to include_sexp([:cmd, 'ant test', options])
    end
  end
end
