; AOC 2024 day 8 part 1

(local arg (. arg 1))
(if (not arg) (error "Missing command line argument"))
(local arg (io.open arg))
(if (not arg) (error "File does not exist"))
(let [done false]
 (while (not done)
  (local line (arg:read "l"))
  (if (and line (> (length line) 0)) (
    (print line)
    (print "\n")
   ) (
    var done true
   )
  )
 )
)
