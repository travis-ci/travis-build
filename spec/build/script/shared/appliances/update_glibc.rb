shared_examples_for 'update libc6' do
  let(:command) { [:echo, 'Forcing update of libc6', ansi: :yellow] }

  context "when update_glibc is unset" do
    it 'updates libc6' do
      should_not include_sexp(command)
    end
  end

  context "when sudo is enabled" do
    before :each do
      data[:paranoid] = false
    end

    it 'updates libc6' do
      should_not include_sexp(command)
    end
  end

  context "when update_glibc is unset" do
    let(:sexp) { sexp_find(subject, [:if, '${TRAVIS_OS_NAME} == linux && ${TRAVIS_DIST} == precise']) }

    before :each do
      Travis::Build.config.update_glibc = '1'
      data[:paranoid] = true
    end

    it 'updates libc6' do
      should include_sexp(command)
    end

    after :each do
      Travis::Build.config.update_glibc = ''
    end
  end
end
