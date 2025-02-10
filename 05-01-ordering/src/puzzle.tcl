if { $argc != 1 } {
    puts stderr "Need filename as argument."
    exit 1
}

proc is_empty {s} {
    return [expr {$s == ""}]
}

# Final result
set total 0

# partial: Dict representing graph edges
# order: Dict representing all edges reachable from each edge

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
dict for {a queue} $partial {
##    puts "A $a"
    # Seen list resets once per root
    set seen ""
    # Starting from loop, repeat bfs search until graph exhausted
    while {[expr {0 < [llength $queue]}]} {
##        puts "Pass: $queue"
##        puts "Len: [llength $queue]"
        # Start building queue for next loop
        set queue_next ""

        # For each edge we have to check this loop
        foreach b $queue {
##            puts "seen: {$seen} check: $b [dict exists $seen $b]"
            # If edge not already seen for this root
            if {![dict exists $seen $b]} {
                # Preserve final result
                dict lappend order $a $b
                # Ensure we don't revisit this edge
                dict set seen $b 1
                # Queue all edges visible from this edge
                if [dict exists $partial $b] {
                    foreach b2 [dict get $partial $b] {
##                        puts "inner: $b2"
                        lappend queue_next $b2
                    }
                }
            }
        }
        # Repeat with new queue
        set queue $queue_next
    }
##    puts ""
}
puts $order
puts ""

unset partial a b b2 seen queue queue_next

# Extract update candidates
while 1 {
    set line [gets $input]
    if [is_empty $line] break
    set line [split $line ","]
    puts $line
}

unset line
close $input

puts "\n$total"