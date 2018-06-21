shared_examples_for 'starts services' do
  before  { data[:config][:services] = services }

  describe 'if services were given' do
    let(:services) { [:postgresql] }

    describe 'postgresql' do
      it { should include_sexp [:cmd, 'sudo service postgresql start', echo: true, timing: true] }
      it { store_example 'service postgresql' if data[:config][:language] == :ruby }
    end

    describe 'Postgresql' do
      let(:services) { [:Postgresql] }
      it { should include_sexp [:cmd, 'sudo service postgresql start', echo: true, timing: true] }
      it { should include_sexp [:cmd, 'sudo systemctl start postgresql@9.6-main', echo: true, timing: true] }
    end

    describe 'redis' do
      let(:services) { [:redis] }
      it { should include_sexp [:cmd, 'sudo service redis-server start', echo: true, timing: true] }
    end

    describe 'mongodb' do
      let(:services) { [:mongodb] }
      it "starts appropriate service based on $TRAVIS_DIST value" do
        expect(sexp_find(subject, [:if, '"$TRAVIS_DIST" == precise']))
          .to include_sexp(
            [:cmd, 'sudo service mongod start', echo: true, timing: true]
          )
        expect(
          sexp_find(subject, [:if, '"$TRAVIS_DIST" == precise'], [:else])
        ).to include_sexp(
          [:cmd, 'sudo service mongodb start', echo: true, timing: true]
        )
      end
    end

    describe 'mysql' do
      let(:services) { [:mysql] }
      it 'starts mysql and then travis_waits for ping' do
        expect(subject)
          .to include_sexp(
            [:cmd, 'sudo service mysql start', echo: true, timing: true]
          )
        expect(subject)
          .to include_sexp(
            [:cmd, 'travis_mysql_ping']
          )
      end
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
