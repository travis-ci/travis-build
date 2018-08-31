export TRAVIS_BUILD_ROOT="<%= root %>"
export TRAVIS_BUILD_HOME="<%= home %>"
export TRAVIS_BUILD_DIR="<%= build_dir %>"
export TRAVIS_BUILD_INTERNAL_RUBY_REGEX="<%= internal_ruby_regex %>"

if [[ -s "${TRAVIS_BUILD_ROOT}/etc/profile" ]]; then
  source "${TRAVIS_BUILD_ROOT}/etc/profile"
fi

if [[ -s "${TRAVIS_BUILD_HOME}/.bash_profile" ]] ; then
  source "${TRAVIS_BUILD_HOME}/.bash_profile"
fi

echo "source ${TRAVIS_BUILD_HOME}/.travis/job_stages" >>"${TRAVIS_BUILD_HOME}/.bashrc"

mkdir -p "${TRAVIS_BUILD_HOME}/.travis"

cat >>"${TRAVIS_BUILD_HOME}/.travis/job_stages" <<'TRAVIS_JOB_STAGES_HEADER'
<%= partial 'stages_header' %>
TRAVIS_JOB_STAGES_HEADER

<%= partial 'temporary_hacks' %>

mkdir -p "${TRAVIS_BUILD_DIR}"
cd "${TRAVIS_BUILD_DIR}"
