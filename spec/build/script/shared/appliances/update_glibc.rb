shared_examples_for 'update libc6' do
  let(:command) { [:cmd, 'travis_apt_get_update'] }

  context "when update_glibc is unset" do
    it 'updates libc6' do
      skip 'spec requires less generic assertion' 
      should_not include_sexp(command)
    end
  end

  context "when sudo is enabled" do
    before :each do
      data[:paranoid] = false
    end

    it 'updates libc6' do
      skip 'spec requires less generic assertion' 
      should_not include_sexp(command)
    end
  end

  context "when update_glibc is unset" do
    let(:sexp) { sexp_find(subject, [:if, "-n $(command -v lsb_release) && $(lsb_release -cs) = 'precise'"]) }

    before :each do
      Travis::Build.config.update_glibc = '1'
      data[:paranoid] = true
    end

    it 'updates libc6' do
      skip 'spec requires less generic assertion' 
      should include_sexp(command)
    end

    after :each do
      Travis::Build.config.update_glibc = ''
    end
  end
end
