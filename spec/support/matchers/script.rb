RSpec::Matchers.define :include_shell do |expected|
  match do |code|
    shell_include?(code, expected)
  end

  failure_message do |code|
    "Expected the following script to include #{expected.inspect}, but it didn't:\n\n#{code}"
  end

  failure_message_when_negated do |code|
    "Expected the generated script to not include #{expected.inspect}."
  end
end

