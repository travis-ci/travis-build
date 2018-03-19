shared_examples_for 'fix sudo-enabled trusty' do
  it 'unsets _JAVA_OPTIONS' do
    should include_sexp [:cmd, 'unset _JAVA_OPTIONS']
  end

  it 'unsets MALLOC_ARENA_MAX' do
    should include_sexp [:cmd, 'unset MALLOC_ARENA_MAX']
  end
end
