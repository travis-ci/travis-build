require 'spec_helper'

describe Travis::Build::Script::Addons::CoverityScan, :sexp do
  let(:config) { {} }
  let(:data)   { PAYLOADS[:push].deep_clone }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.script }

  # it { p subject }
end
