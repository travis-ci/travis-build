mkdir ~/bin
cat > ~/bin/xcodebuild <<EOF
#!/usr/bin/env perl

my $status = 1;

open my $fh, "-|", @ARGV
  or die "unable to run command: $!\n";

while (my $line = readline($fh)) {
	print $line;
	$status = 0 if $line =~ /^\*\* TEST SUCCEEDED \*\*$/;
}

close $fh;

exit $status;
EOF
chmod +x ~/bin/xcodebuild

export PATH="$HOME/bin:$PATH"