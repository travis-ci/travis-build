shared_examples_for 'disables updating initramfs' do
  let(:disable_initramfs) { %(if [ ! $(uname|egrep 'Darwin|FreeBSD') ]; then echo update_initramfs=no | sudo tee -a /etc/initramfs-tools/update-initramfs.conf > /dev/null; fi) }

  it 'disables updating initramfs' do
    should include_sexp [:raw, disable_initramfs]
  end
end
