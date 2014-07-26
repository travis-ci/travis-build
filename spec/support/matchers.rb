RSpec::Matchers.define :include_sexp do |expected|
  match do |actual|
    sexp_includes?(actual, expected)
  end

  failure_message do |script|
    "Expected the following sexp to include #{expected}, but it didn't:\n\n#{actual}"
  end

  failure_message_when_negated do |script|
    "Expected the following sexp to not include #{expected}, but it did:\n\n#{actual}"
  end
end
