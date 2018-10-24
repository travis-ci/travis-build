shared_examples_for 'starts services' do
  before  { data[:config][:services] = services }

  describe 'if services were given' do
    let(:services) { [:postgresql] }

    describe 'postgresql' do
      it { should include_sexp [:cmd, 'travis_setup_postgresql', echo: true, timing: true] }
      it { store_example(name: 'service postgresql') if data[:config][:language] == :ruby }
    end

    describe 'Postgresql' do
      let(:services) { [:Postgresql] }
      it { should include_sexp [:cmd, 'travis_setup_postgresql', echo: true, timing: true] }
    end

    describe 'redis' do
      let(:services) { [:redis] }
      it { should include_sexp [:cmd, 'sudo service redis-server start', echo: true, timing: true] }
      it { should include_sexp [:cmd, 'sudo systemctl start redis-server', echo: true, timing: true] }
    end

    describe 'mongodb' do
      let(:services) { [:mongodb] }
      it "starts appropriate service based on $TRAVIS_DIST value" do
        expect(sexp_find(subject, [:if, '"$TRAVIS_DIST" == precise']))
          .to include_sexp(
            [:cmd, 'sudo service mongodb start', echo: true, timing: true]
          )
        expect(
          sexp_find(subject, [:if, '"$TRAVIS_DIST" == precise'], [:elif])
        ).to include_sexp(
          [:cmd, 'sudo service mongod start', echo: true, timing: true]
        )
      end

      it "starts service based on init system" do
        expect(sexp_find(subject, [:elif, '"$TRAVIS_INIT" == upstart']))
          .to include_sexp(
            [:cmd, 'sudo service mongod start', echo: true, timing: true]
          )
        expect(sexp_find(subject, [:elif, '"$TRAVIS_INIT" == systemd']))
          .to include_sexp(
            [:cmd, 'sudo systemctl start mongod', echo: true, timing: true]
          )
      end
    end

    describe 'travis_daemon' do
      let(:services) { [:travis_daemon] }
      it "adheres to init system" do
        expect(sexp_find(subject, [:if, '"$TRAVIS_INIT" == upstart']))
          .to include_sexp(
            [:cmd, 'sudo service travis_daemon start', echo: true, timing: true]
          )
        expect(sexp_find(subject, [:elif, '"$TRAVIS_INIT" == systemd']))
          .to include_sexp(
            [:cmd, 'sudo systemctl start travis_daemon', echo: true, timing: true]
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
