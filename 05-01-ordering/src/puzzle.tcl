if { $argc != 1 } {
    puts stderr "Need filename as argument."
    exit 1
}

proc is_empty {s} {
    return [expr {$s == ""}]
}

# Final result
set total 0

# partial: Dict representing a shallow graph (noop)
# order: Dict representing all paths in graph

# Begin
set input [open [lindex $argv 0] r]

# Extract ordering
while 1 {
    set line [gets $input]
    if [is_empty $line] break

    lassign [split $line "|"] a b

    dict lappend partial $a $b
}

puts $partial
dict for {a blist} $partial {
    foreach b $blist {
        while 1 {
            dict lappend order $a $b
            if {![dict exists $partial $b]} break
            set b [dict get $partial $b]
        }
    }
}
puts $order
puts ""

unset partial a b blist

# Extract update candidates
while 1 {
    set line [gets $input]
    if [is_empty $line] break
    set line [split $line ","]
    puts $line
}

unset line
close $input
