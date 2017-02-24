RSpec::Matchers.define :match_sexp do |expected|
  match do |sexp|
    sexp_find(sexp, expected).any?
  end

  failure_message do |sexp|
    "Expected the following sexp to include #{expected}, but it didn't:\n\n#{sexp}"
  end

  failure_message_when_negated do |sexp|
    "Expected the following sexp to not include #{expected}, but it did:\n\n#{sexp}"
  end
end

RSpec::Matchers.define :include_sexp do |expected|
  match do |sexp|
    sexp_includes?(sexp, expected)
  end

  failure_message do |sexp|
    "Expected the generated sexp to include:\n\n#{expected}#{similar_nodes(sexp, expected.first)}"
  end

  def similar_nodes(sexp, type)
    sexps = sexp_filter(sexp, [expected.first])
    sexps = sexps.map(&:inspect).join("\n")
    "\n\nFound the following similar nodes:\n\n#{sexps}" unless sexp.empty?
  end

  failure_message_when_negated do |sexp|
    "Expected the following sexp to not include #{expected}"
  end
end

RSpec::Matchers.define :include_deprecation_sexp do |msg|
  match do |sexp|
    sexp = sexp_filter(sexp, [:echo]).detect { |echo| echo[1] =~ msg }
    sexp && sexp[1][0, 10] == 'DEPRECATED' && sexp[2] && sexp[2][:ansi] = :red
  end

  failure_message do |sexp|
    "Expected the following sexp to include #{expected}, but it didn't:\n\n#{sexp}"
  end

  failure_message_when_negated do |sexp|
    "Expected the following sexp to not include #{expected}, but it did:\n\n#{sexp}"
  end
end
