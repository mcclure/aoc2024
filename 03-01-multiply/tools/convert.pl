# Per my rules I can use text transformers to inject input files into code

# Usage: cat data/sample.161.txt | perl tools/convert.pl > src/sample.s

# Usage: cat data/puzzle.txt | perl tools/convert.pl > src/puzzle.s

{
local $/;

$_ = <>;
}

s/\\/\\\\/sg;
s/\"/\\\"/sg;
s/\n/\\n/sg; # No multiline string support

my $input = $_;

open(FH, "src/base.s");
while(<FH>) {
	if (/^\#\s*\!{10}/) {
		print qq[input: .asciz "$input"\n];
	} else {
		print $_;
	}
}
