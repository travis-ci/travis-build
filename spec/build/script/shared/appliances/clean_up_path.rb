shared_examples_for 'cleans up $PATH' do

  it 'removes empty path from $PATH' do
    should include_sexp [ :export, ['PATH', "$(echo $PATH | sed -e 's/::/:/g')" ] ]
  end

  it 'removes duplicates from $PATH' do
    should include_sexp [ :export, ['PATH', "$(echo -n $PATH | perl -e 'print join(\":\", grep { not $seen{$_}++ } split(/:/, scalar <>))')" ] ]
  end
end