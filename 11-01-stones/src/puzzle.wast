;; AOC day 11 part 1
;; python3 tools/prep.py src/puzzle.wast INPUT="<data/sample.unknown.txt>" MEMORY=1 ROUNDS=25

(module
  ;; Note to third parties. ;; followed by : invokes my preprocessor;
  ;; Instances of "000" get deleted, and are only present to make my syntax highlighter happy
  (memory 000
    ;;: insert MEMORY
  )
  (data
    (i32.const 0)
    ;; Global LEN: Array length + 2 (eg length of full memory)
    ;;: set LENP=0
    ;;: insert INPUT|i32|len|+:8|i32|bin

    ;; Global PASS: Passes complete
    ;;: set PASSP=4
    "\00\00\00\00"

    ;; Global ARRAY: Start of data array
    ;;: set ARRAY=8
    ;;: insert INPUT|i32|bin
  )
  ;; (func $push (param $start i32) (local $digits i32)
  ;;   (local.set $digits (i32.load (i32.const 0)))
  ;;   (local.get $digits)
  ;; )
  (func $run (result i32) (local $digits i32)
    (local.set $digits (i32.load (i32.const 0)))
    (local.get $digits)

    ;; Convert offset to count
    (i32.const 4)
    (i32.div_u)
    (i32.sub (i32.const 2))
  )
  (export "run" (func $run))
)
