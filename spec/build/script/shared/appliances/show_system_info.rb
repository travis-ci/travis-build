shared_examples_for 'show system info' do
  let(:sexp) { sexp_find(subject, [:fold, 'system_info']) }

  let(:echo_notice)    { [:echo, "Build system information", ansi: :yellow] }
  let(:echo_language)  { [:echo, /Build language/] }
  let(:echo_group)     { [:echo, 'Build group: dev'] }
  let(:echo_dist)      { [:echo, 'Build dist: trusty'] }
  let(:echo_build_id)  { [:echo, /Build id: \d+/] }
  let(:echo_job_id)    { [:echo, /Job id: \d+/] }
  let(:path)           { '/usr/share/travis/system_info' }
  let(:system_info)    { [:cmd, "cat #{path}"] }
  let(:secondary_path) { '/usr/local/travis/system_info' }
  let(:secondary_info) { [:cmd, "cat #{secondary_path}"] }

  it 'displays a header message' do
    expect(sexp).to include_sexp echo_notice
  end

  it 'displays the build script language' do
    expect(sexp).to include_sexp echo_language
  end

  describe 'if group is given' do
    before { data[:config][:group] = 'dev' }

    it 'displays the build image group' do
      expect(sexp).to include_sexp echo_group
    end
  end

  describe 'if dist is given' do
    before { data[:config][:dist] = 'trusty' }

    it 'displays the build image dist' do
      expect(sexp).to include_sexp echo_dist
    end
  end

  describe 'if build and job ids are given' do
    before { data[:config][:build] = { id: 1234 } }
    before { data[:config][:job] = { id: 5678 } }

    it 'displays the build and job ids' do
      expect(sexp).to include_sexp echo_build_id
      expect(sexp).to include_sexp echo_job_id
    end
  end

  it 'runs command if the system info file exists' do
    branch = sexp_find(sexp, [:if, "-f #{path}"], [:then])
    expect(branch).to include_sexp system_info
  end

  it 'runs secondary command if the secondary system info file exists' do
    branch = sexp_find(sexp, [:if, "-f #{secondary_path}"], [:then])
    expect(branch).to include_sexp secondary_info
  end
end
