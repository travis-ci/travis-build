shared_examples_for 'setup filter' do
  let(:filter) {[:echo, 'Secret environment variables are not obfuscated on Windows, please refer to our documentation: https://docs.travis-ci.com/user/best-practices-security', ansi: 'yellow']}

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
