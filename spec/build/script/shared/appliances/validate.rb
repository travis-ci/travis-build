shared_examples_for 'validates config' do
  let(:fetch_error)    { [:echo, 'Could not fetch .travis.yml from GitHub.', ansi: :red] }
  let(:missing_config) { [:echo, 'Could not find .travis.yml, using standard configuration.', ansi: :red] }
  let(:terminate)      { [:raw, 'travis_terminate 2'] }
  let(:run_script)     { [:cmd, './the_script', echo: true, timing: true] }

  before do
    data[:config][:'.result'] = result
    data[:config][:script] = './the_script'
  end

  describe 'server error' do
    let(:result) { 'server_error' }
    it { should include_sexp fetch_error }
    it { should include_sexp terminate }
    it { should_not include_sexp run_script }
    it { store_example(name: 'config server error') if data[:config][:language] == :ruby }
  end

  describe 'not found' do
    let(:result) { 'not_found' }
    it { should include_sexp missing_config }
    it { should_not include_sexp terminate }
    it { should include_sexp run_script }
    it { store_example(name: 'config not found') if data[:config][:language] == :ruby }
  end
end
