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

# partial: Dict representing "a must precede b"

# Begin
set input [open [lindex $argv 0] r]

# Extract ordering
while 1 {
    set line [gets $input]
    if [is_empty $line] break

    lassign [split $line "|"] a b

    # Notice: Our edges point from the *right* of the | to the *left*
    dict lappend partial $a $b
}

drop a b seen
puts $partial

# Test update candidates
# The problem statement is confusing: 
while 1 {
    set line [gets $input]
    if [is_empty $line] break
    set line [split $line ","]
    set lline [llength $line]
    set valid 1
    if {$lline % 2 != 1} {error "Even numbered line? ($lline)"}
    puts "line {$line} lline {$lline}"
    for {set idx 0} {$valid && $idx < $lline-1} {incr idx} {
        puts "\tIndex $idx"
        set a [lindex $line $idx]
        if [dict exists $partial $a] {
            set test [lrange $line [expr {$idx+1}] $lline]
            puts "\ta {$a} test {$test}"
            foreach b [dict get $partial $a] {
                set valid [expr {$valid && ($b in $test)}]
                if [expr {!$valid}] {
                    puts "\t\tRejected: Did not find $b"
                    break
                }
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

drop line test a b valid pass_valid
close $input

puts "$total"
