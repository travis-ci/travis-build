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

PAYLOADS = {
  :push => {
    'type' => 'test',
    'config' => {
      'env' => ['FOO=foo', 'SECURE BAR=bar'],
      'before_install' => ['./before_install_1.sh', './before_install_2.sh'],
      'before_script'  => ['./before_script_1.sh',  './before_script_2.sh'],
      'after_script'   => ['./after_script_1.sh',   './after_script_2.sh'],
      'after_success'  => ['./after_success_1.sh',  './after_success_2.sh'],
      'after_failure'  => ['./after_failure_1.sh',  './after_failure_2.sh'],
      'deploy'         => ['./deploy_1.sh',         './deploy_2.sh'],
      'os' => 'linux',
    },
    'repository' => {
      'slug' => 'travis-ci/travis-ci',
      'source_url' => 'git://github.com/travis-ci/travis-ci.git'
    },
    'source' => {
      'id' => 1,
      'number' => 1
    },
    'job' => {
      'id' => 1,
      'number' => '1.1',
      'commit' => '313f61b',
      'branch' => 'master',
      'commit_range' => '313f61b..313f61a',
      'commit_message' => 'the commit message',
      'secure_env_enabled' => true
    },
    ssh_key: {
      encoded: false,
      value: TEST_PRIVATE_KEY,
      source: 'default'
    }
  }
}
