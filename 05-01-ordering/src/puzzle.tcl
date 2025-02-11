if { $argc != 1 } {
    puts stderr "Need filename as argument."
    exit 1
}

proc is_empty {s} {
    return [expr {$s == ""}]
}

# Unconditional unset
proc drop {args} {
    foreach v $args {
        upvar $v x
        if [info exists x] {unset x}
    }
}

# Final result
set total 0

# partial_for: Dict representing graph edges
# partial_rev: Dict representing graph edges (reverse)
# order: Dict representing all edges reachable from each edge
# order_rev: Dict representing all edges reachable from each edge (reverse)

# Begin
set input [open [lindex $argv 0] r]

# Extract ordering
while 1 {
    set line [gets $input]
    if [is_empty $line] break

    lassign [split $line "|"] a b

    dict lappend partial_for $a $b
    dict lappend partial_rev $b $a
}

puts "Forward: $partial_for"
puts "Reverse: $partial_rev"

proc extend {partial} {
    return $partial
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
    return $order
}

set order_for [extend $partial_for]
set order_rev [extend $partial_rev]

puts "Forward full: $order_for"
puts "Reverse full: $order_rev"
puts ""

drop partial_for partial_rev

# Extract update candidates
while 1 {
    set line [gets $input]
    if [is_empty $line] break
    set line [split $line ","]
    set lline [llength $line]
    set valid 1
    if {$lline % 2 != 1} {error "Even numbered line?"}
    puts "line {$line} lline {$lline}"
    for {set idx 0} {$valid && $idx < $lline-1} {incr idx} {
##        puts "Index $idx"
        set a [lindex $line $idx]
        set test [lrange $line [expr {$idx+1}] $lline]
##        puts "a {$a} test {$test}"
        foreach b $test {
##            puts "$a $b? [dict exists $order $a]"
            if [expr {
                ![dict exists $order_for $a] || !($b in [dict get $order_for $a]) ||
                ![dict exists $order_rev $b] || !($a in [dict get $order_rev $b])
            }] {
                puts "Invalid pair: $a $b\n"
                set valid 0
                break
            }
        }
    }
    if $valid {
        puts "Valid: $line"
        set middle [lindex $line [expr $lline/2]]
        puts "Middle: $middle\n"
        set total [expr $total+$middle]
    }
}

drop line test a b
close $input

puts "$total"
