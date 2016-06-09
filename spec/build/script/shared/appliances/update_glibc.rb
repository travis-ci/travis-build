shared_examples_for 'update glibc' do
  let(:update_glibc) {
    <<-EOF
if [ ! $(uname|grep Darwin) ]; then
  sudo -E apt-get -yq update 2>&1 >> ~/apt-get-update.log
  sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install libc6
fi
    EOF
  }
  it 'updates glibc' do
    should include_sexp [:cmd, update_glibc]
  end

  it 'skips updating glibc if disabled in config' do
    data[:appliances_switches] = {
      :update_glibc => false
    }
    should_not include_sexp [:cmd, update_glibc]
  end

end
