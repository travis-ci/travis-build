require 'fileutils'
require 'sinatra/test_helpers'

require 'travis/build'

require 'support/matchers'
require 'support/mock_shell'
require 'support/payloads'

require 'shared/git'
require 'shared/jdk'
require 'shared/jvm'
require 'shared/script'
require 'shared/env_vars'

STDOUT.sync = true

class Hash
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

module SpecHelpers
  CONST = {}

  def replace_consts
    replace_const 'Travis::Build::Script::TEMPLATES_PATH', 'spec/templates'
    replace_const 'Travis::Build::HOME_DIR', '.'
    replace_const 'Travis::Build::BUILD_DIR', './tmp'
  end

  def replace_const(const, value)
    CONST[const] = eval(const).dup
    eval "#{const}.replace(#{value.inspect})"
  end

  def restore_consts
    CONST.each do |name, value|
      eval "#{name}.replace(#{value.inspect})"
    end
  end

  def executable(name)
    file(name, "builtin echo #{name} $@;")
    FileUtils.chmod('+x', "tmp/#{name}")
  end

  def file(name, content = '')
    path = "tmp/#{name}"
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w+') { |f| f.write(content) }
  end

  def directory(name)
    path = "tmp/#{name}"
    FileUtils.mkdir_p(path)
  end

  def gemfile(name)
    file(name)
    data['config']['gemfile'] = name
  end

  def store_example(name = nil)
    # restore_consts
    # name = [described_class.name.split('::').last.gsub(/([A-Z]+)/,'_\1').gsub(/^_/, '').downcase, name].compact.join('_').gsub(' ', '_')
    # script = described_class.new(data, options).compile
    # File.open("examples/build_#{name}.sh", 'w+') { |f| f.write(script) }
  end
end

RSpec.configure do |c|
  c.include SpecHelpers
  c.deprecation_stream = 'rspec.log'
  c.mock_with :mocha
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  c.filter_run_excluding clean_room: true unless ENV['TRAVIS']
  c.formatter = 'documentation'
  c.include Sinatra::TestHelpers, :include_sinatra_helpers
  # c.backtrace_clean_patterns.clear

  c.before :each do
    FileUtils.rm_rf 'tmp'
    FileUtils.mkdir 'tmp'
    FileUtils.rm_rf 'examples'
    FileUtils.mkdir 'examples'
  end

  c.before :each do
    replace_consts
  end

  c.after :each do
    restore_consts
  end
end

class RSpec::Core::Example
  def passed?
    @exception.nil?
  end

  def failed?
    !passed?
  end
end

TEST_PRIVATE_KEY = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA6Dm1n+fc0ILeLWeiwqsWs1MZaGAfccrmpvuxfcE9UaJp2POy
079g+mdiBgtWfnQlU84YX31rU2x9GJwnb8G6UcvkEjqczOgHHmELtaNmrRH1g8qO
fJpzXB8XiNib1L3TDs7qYMKLDCbl2bWrcO7Dol9bSqIeb7f9rzkCd4tuXObL3pMD
/VIW5uzeVqLBAc0Er+qw6U7clnMnHHMekXt4JSRfauSCxktR2FzigoQbJc8t4iWO
rmNi5Q84VkXB3X7PO/eajUw+RJOl6FnPN1Zh08ceqcqmSMM4RzeVQaczXg7P92P4
mRF41R97jIJyzUGwheb2Z4Q2rltck4V7R5BvMwIDAQABAoIBAE4O3+MRH+MiqiXe
+RGwSqAaZab08Hzic+dbIQ0hQEhJbITVXZ3ZbXKd/5ACjZ9R0R47X2vxj3rqM55r
FsJ0/vjxrQcHlp81uvbWLgZvF1tDdyBGnOB7Vh14AgQoszCuYdxPZu8BVZXPGWG1
tBvw1eelX91VYx+wW+BjLFYckws8kPCPY6WEnng0wQGShGqyTOJa1T4M1ethHYF+
ddNx+fVLkEf2vL59popuJMOAyVa1jvU7D3VZ67qhlxWAvQxZeEP0vFZHeWPjvRF1
orxiGuwLCG+Rgq1XSVJjMNf1qE3gZTlDg+u3ORKbRx2xlhiqpkHxLx7QtCmELwtD
Dqvf8ukCgYEA/SoQwyfMp4t19FLI4tV0rp3Yn7ZSAqRtMVrLVAIQoJzDXv9BaJFS
xb6enxRAjy+Rg10H8ijh8Z9Z3a4g3JViHQsWMrf9rL2/7M07vraIUIQoVo7yTeGa
MXnTuKmBZFGEAM9CzqAVao1Om10TRFNLgiLAU3ZEFi8J1DYWkhzrJp0CgYEA6tOa
V15MP3sJSlOTszshXKbwf6iXfjHbdpGUXmd9X3AMzOvl/CEGS2q46lwJISubHWKF
BOKk1thumM4Zu6dx89hLEoXhFycgUV/KJYl54ZfhY079Ri7SZUYIqDR04BRJC2d6
mO16Y//UwqgTaZ/lS/S791iWPTjVNEgSlRbQHA8CgYALiOEeoy+V6qrDKQpyG1un
oRV/oWT3LdqzxvlAqJ9tUfcs2uB2DTkCPX8orFmMrJQqshBsniQ9SA9mJErnAf9o
Z1rpkKyENFkMRwWT2Ok5EexslTLBDahi3LQi08ZLddNX3hmjJHQVWL7eIU2BbXIh
ScgNhXPwts/x1U0N9zdXmQKBgQC4O6W2cAQQNd5XEvUpQ/XrtAmxjjq0xjbxckve
OQFy0/0m9NiuE9bVaniDXgvHm2eKCVZlO8+pw4oZlnE3+an8brCParvrJ0ZCsY1u
H8qgxEEPYdRxsKBe1jBKj0U23JNmQBw+SOqh9AAfbDA2yTzjd7HU4AqXI7SZ3QW/
NHO33wKBgQCqxUmocyqKy5NEBPMmeHWapuSY47bdDaE139vRWV6M47oxzxF8QnQV
1TGWsshK04QO8wsfzIa9/SjZkU17QVkz7LXbq4hPmiZjhP/H+roCeoDEyHFdkq6B
bm/edpYemlJlQhEYtecwvD57NZbVuaqX4Culz9WdSsw4I56hD+QjHQ==
-----END RSA PRIVATE KEY-----
"
