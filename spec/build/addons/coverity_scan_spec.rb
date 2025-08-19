require 'spec_helper'

describe Travis::Build::Addons::CoverityScan, :sexp do
  let(:script) { stub('script') }
  let(:config) { { project: { name: 'test' } } }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { coverity_scan: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.script }

  it { is_expected.to include_sexp [:cmd, 'curl -s https://scan.coverity.com/scripts/travisci_build_coverity_scan.sh | COVERITY_SCAN_PROJECT_NAME="$PROJECT_NAME" COVERITY_SCAN_NOTIFICATION_EMAIL="${COVERITY_SCAN_NOTIFICATION_EMAIL:-}" COVERITY_SCAN_BUILD_COMMAND="${COVERITY_SCAN_BUILD_COMMAND:-}" COVERITY_SCAN_BUILD_COMMAND_PREPEND="${COVERITY_SCAN_BUILD_COMMAND_PREPEND:-}" COVERITY_SCAN_BRANCH_PATTERN=${COVERITY_SCAN_BRANCH_PATTERN:-} /bin/sh', { echo: true }] }
  it { is_expected.to include_sexp [:raw, 'result=$?'] }
  it { is_expected.to include_sexp [:if, '$result -ne 0', [:then, [:cmds, [[:raw, "echo -e \"\e[33;1mSkipping build_coverity due to script error\e[0m\""], [:raw, 'exit 1']]]]] }
end
