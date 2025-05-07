; AOC 2024 day 8 part 1

(local vec2 (require :vec2))
(local bound2 (require :bound2))

; Open file
(local arg (. arg 1))
(if (not arg) (error "Missing command line argument"))
(local arg (io.open arg))
(if (not arg) (error "File does not exist"))

; State (1)
(local letters {})
(fn add-letter [char v]
  (when (not (. letters char))
    (tset letters char {})
  )
  (table.insert (. letters char) v)
)

; File parser
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
      (add-letter char (vec2 x y))
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
(io.close arg)

; state (2)
(fn keys-count [t] ; get number of keys in table
  (var result 0)
  (each [k _ (pairs t)]
    (set result (+ result 1))
  )
  result
)
(local size (vec2 xmax y))
(local bound (bound2 vec2.zero (- size (vec2 1 1))))
(var antinodes 0)
(local antinodes-unique {})
(fn add-antinode-unique [v]
  (local key (+ v.y (* v.x size.x)))
  (tset antinodes-unique key 1)
)

; Run program

(print)
(print "size")
(print size)
(print)
(print "letters")
(print (keys-count letters))
(print)

(each [k t (pairs letters)] ; For each letter,
  (print (.. k ":"))
  (each [i v (ipairs t)] ; for each station,
    (for [i2 (+ i 1) (length t)] ; pair off against each station,
      (local v2 (. t i2))
      (local diff (- v2 v))
      (print (.. i " vs " i2 " (" (tostring v) ", " (tostring v2) "):"))
      (each [_ antinode (ipairs [(+ v2 diff) (- v diff)])] ; each station pair produces two antinodes,
        (local ok (bound:contains antinode))
        (print (.. (tostring antinode) (if ok " (OK)" "")))
        (when ok ; if it's in 
          (set antinodes (+ antinodes 1))
          (add-antinode-unique antinode)
        )
      ) 
    )
  )
)

(print)
(print "antinodes")
(print antinodes)
(print "unique")
(print (keys-count antinodes-unique))
