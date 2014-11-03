shared_examples_for 'starts services' do
  before  { data[:config][:services] = services }

  describe 'if services were given' do
    let(:services) { [:postgresql] }

    subject { sexp_find(super(), [:fold, 'services']) }

    describe 'folds the services section' do
      it { should_not be_empty }
    end

    describe 'postgresql' do
      it { should include_sexp [:cmd, 'sudo service postgresql start', echo: true, timing: true] }
    end

    describe 'Postgresql' do
      let(:services) { [:Postgresql] }
      it { should include_sexp [:cmd, 'sudo service postgresql start', echo: true, timing: true] }
    end

    describe 'redis' do
      let(:services) { [:redis] }
      it { should include_sexp [:cmd, 'sudo service redis-server start', echo: true, timing: true] }
    end

    describe 'sleeps 3 secs after starting the services' do
      it { should include_sexp [:raw, 'sleep 3'] }
    end
  end

  describe 'if no services were given' do
    let(:services) { }

    it { should_not include_sexp [:fold, 'services'] }
    it { should_not include_sexp [:raw, 'sleep 3'] }
  end
end
