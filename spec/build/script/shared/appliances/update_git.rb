shared_examples_for "update git" do
  let(:command) {[:cmd, <<-EOF
if [ ! $(uname|grep Darwin) ]; then
  DEBIAN_FRONTEND=noninteractive sudo -E apt-get -yq update 2>&1 >> ~/apt-get-update.log
  DEBIAN_FRONTEND=noninteractive sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install git
fi
  EOF
  ]}

  context "when update_git is unset" do
    it "does not update git" do
      should_not include_sexp(command)
    end
  end

  context "when update_git is set" do
    before :each do
      Travis::Build.config.update_git = "1"
    end

    it "updates git" do
      should include_sexp(command)
    end

    after :each do
      Travis::Build.config.update_glibc = ""
    end
  end
end
