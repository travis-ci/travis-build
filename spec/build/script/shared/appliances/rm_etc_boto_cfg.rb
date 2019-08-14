shared_examples_for 'remove /etc/boto.cfg' do
  let(:rm_etc_boto_cfg) { "rm -f /etc/boto.cfg" }

  it "removes /etc/boto.cfg" do
    should include_sexp [:cmd, rm_etc_boto_cfg, sudo: true]
  end

end
