# Per my rules I can use text transformers to inject input files into code,
# but I don't want to actually offload complexity, so I will be trying to let
# my transformers "help" as little as possible.
# In the case of this one, it means I'm going to keep the "two inputs per line" structure.

# Usage: cat data/puzzle.txt | perl tools/convert.pl > scratch/suffix.txt

my @lines;
while(<>) {
	my @line = split(/\s+/, $_);
	if (@line > 1) {
		push(@lines, \@line);
	}
}

print "30000 REM FORMAT: 1 LINE SIZE, N LINES NUMBER PAIRS, 1 LINE -1\n";
print "30001 DATA ";
print 0+@lines;
print "\n";

$ln = 30002;
for my $line (@lines) {
	print "$ln DATA ";
	print join(",", @$line);
	print "\n";
	$ln++;
}
print "$ln DATA -1\n"
