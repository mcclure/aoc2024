if { $argc != 1 } {
    puts stderr "Need filename as argument."
    exit 1
}

set input [open [lindex $argv 0] r]
puts [gets $input]
close $input
