shared_examples_for 'setup filter' do
  let(:filter) {[:echo, 'Secrets are not currently filtered on Windows, please be careful', ansi: 'yellow']}

  describe 'skips on Windows' do
    before do
      data[:config][:os] = 'windows'
    end

    describe 'skips secrets filtering' do
      it {should include_sexp filter}
    end
  end

  describe 'runs on Linux' do
    before do
      data[:config][:os] = 'linux'
    end

    describe 'skips secrets filtering' do
      it {should_not include_sexp filter}
    end
  end
end
