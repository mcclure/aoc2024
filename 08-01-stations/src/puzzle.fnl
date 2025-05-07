; AOC 2024 day 8 part 1

(local arg (. arg 1))
(if (not arg) (error "Missing command line argument"))
(local arg (io.open arg))
(if (not arg) (error "File does not exist"))
(var done false)
(var y 0)
(var xmax 0)
(while (not done)
 (var x 0)
 (var line (arg:read "l"))
 (if (and line (> (length line) 0)) (
   do
    (each [char (line:gmatch "[^%s]")]
     (when (not= char ".")
      (print x)
      (print ", ")
      (print y)
      (print char)
     )
     (set x (+ x 1))
     (when (< xmax x) (set xmax x))
   )
   (set y (+ y 1))
  ) (
   set done true
  )
 )
)
(print "size")
(print xmax)
(print ",")
(print y)