shared_examples_for 'setup filter' do

  describe 'runs on windows' do
    let(:filter) {[:echo, 'Secrets are not currently filtered on Windows, please be careful', ansi: 'yellow']}

    before do
      data[:config][:os] = 'windows'
    end

    describe 'skips secrets filtering' do
      it {should include_sexp filter}
    end
  end
end
