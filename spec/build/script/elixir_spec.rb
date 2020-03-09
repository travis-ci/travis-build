require 'spec_helper'

describe Travis::Build::Script::Elixir, :sexp do
  let(:data)   { payload_for(:push, :elixir) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=elixir'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_OTP_RELEASE' do
    should include_sexp [:export, ['TRAVIS_OTP_RELEASE', '17.4']] #, echo: true
  end

  it 'sets TRAVIS_ELIXIR_VERSION' do
    should include_sexp [:export, ['TRAVIS_ELIXIR_VERSION', '1.0.2']] #, echo: true
  end

  it 'announces elixir version' do
    should include_sexp [:cmd, 'elixir --version', echo: true]
  end

  describe 'install' do
    it 'runs "mix local.hex"' do
      should include_sexp [:cmd, 'mix local.hex --force', assert: true, echo: true, timing: true]
    end
    it 'runs "mix deps.get"' do
      should include_sexp [:cmd, 'mix deps.get',  assert: true, echo: true, timing: true]
    end
  end

  describe 'script' do
    it 'runs "mix test"' do
      should include_sexp [:cmd, 'mix test', echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq("cache-#{CACHE_SLUG_EXTRAS}--otp-17.4--elixir-1.0.2") }
  end

  def self.installs_required_otp_release(elixir_version, otp_release_wanted, otp_release_required)
    context "when elixir version is #{elixir_version}" do
      before :each do
        data[:config][:elixir] = elixir_version
      end

      context "when OTP release is #{otp_release_wanted}" do
        before :each do
          data[:config][:otp_release] = otp_release_wanted
        end

        if otp_release_wanted == otp_release_required
          describe "wanted OTP release #{otp_release_wanted}" do
            it "is installed" do
              sexp = sexp_find(subject, [:if, "! -f ${TRAVIS_HOME}/otp/#{otp_release_wanted}/activate"], [:then])
              expect(sexp).to include_sexp([:raw, "archive_url=https://s3.amazonaws.com/travis-otp-releases/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/erlang-#{otp_release_wanted}-nonroot.tar.bz2", assert: true])
              expect(sexp).to include_sexp([:cmd, "wget -o ${TRAVIS_HOME}/erlang.tar.bz2 ${archive_url}", assert: true, echo: true, timing: true])
            end
          end
        else
          describe "required OTP release #{otp_release_required}" do
            it "is installed" do
              sexp = sexp_find(subject, [:if, "! -f ${TRAVIS_HOME}/otp/#{otp_release_required}/activate"], [:then])
              expect(sexp).to include_sexp([:raw, "archive_url=https://s3.amazonaws.com/travis-otp-releases/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/erlang-#{otp_release_required}-nonroot.tar.bz2", assert: true])
              expect(sexp).to include_sexp([:cmd, "wget -o ${TRAVIS_HOME}/erlang.tar.bz2 ${archive_url}", assert: true, echo: true, timing: true])
            end
          end
        end
      end
    end
  end

  # requirement met
  installs_required_otp_release(['1.6.0'], '20.0', '20.0')
  installs_required_otp_release('1.6.0', '19.0', '19.0')
  installs_required_otp_release('1.2.0', '18.0', '18.0')
  installs_required_otp_release('1.1.0', '17.4', '17.4')
  installs_required_otp_release('1.1.0', '18.0', '18.0')
  installs_required_otp_release('1.0.5', '17.3', '17.3')
  # requirement not met
  installs_required_otp_release(['1.6.0'], '18.0', '19.0')
  installs_required_otp_release('1.2.0', '17.3', '18.0')
  installs_required_otp_release('1.2.0-dev', '17.4', '18.0')
  installs_required_otp_release('1.0.5', '18.0', '17.4')
  installs_required_otp_release('1.0.5', 'R16B03-1', '17.4')
end
