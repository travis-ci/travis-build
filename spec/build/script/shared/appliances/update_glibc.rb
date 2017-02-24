shared_examples_for 'update libc6' do
  let(:command) { [:cmd, <<-EOF
if [ ! $(uname|grep Darwin) ]; then
  sudo -E apt-get -yq update 2>&1 >> ~/apt-get-update.log
  sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install libc6
fi
  EOF
  ]}

  context "when update_glibc is unset" do
    it 'updates libc6' do
      should_not include_sexp(command)
    end
  end

  context "when update_glibc is unset" do
    before :each do
      Travis::Build.config.update_glibc = '1'
    end

    it 'updates libc6' do
      should include_sexp(command)
    end

    after :each do
      Travis::Build.config.update_glibc = ''
    end
  end
end
