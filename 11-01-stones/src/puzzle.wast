;; AOC day 11 part 1
;; python3 tools/prep.py src/puzzle.wast INPUT="<data/sample.unknown.txt>" MEMORY=1 ROUNDS=25 RESULT=0

;;  MAX_UINT/2024
;;: set WILL_OVERFLOW=2122019

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
    ;;: insert INPUT|i32|len|+:4|i32|bin

    ;; Global ARRAY: Start of data array
    ;;: set ARRAYP=4
    ;;: insert INPUT|i32|bin
  )
  ;; (func $push (param $start i32) (local $digits i32)
  ;;   (local.set $digits (i32.load (i32.const 0)))
  ;;   (local.get $digits)
  ;; )
  (func $run (result i32) (local $pass i32) (local $idx i32)
    (local.set $pass (i32.const 000
        ;;: insert ROUNDS
    ))
    (block $countdown_done
      (loop $countdown
        ;; Loop always starts with $pass atop stack
        (local.get $pass)
        (i32.const 0)
        (i32.eq)
        (br_if $countdown_done)

        (local.set $idx (i32.load (i32.const 000
            ;;: insert LENP
          )))
        (loop $sweep
          (local.get $idx)
          (i32.const 4)
          (i32.sub)
          (local.tee $idx)

          (i32.load) ;; This Is The Number
          drop

          ;; Continue if that wasn't the lowest cell
          (local.get $idx)
          (i32.const 000
              ;;: insert ARRAYP
            )
          (i32.gt_u)
          (br_if $sweep)
        )

        ;; Done; subtract one pass and leave on stack
        (local.get $pass)
        (i32.const 1)
        (i32.sub)
        (local.set $pass)
        (br $countdown)
      )
    )

    ;; Return result
    (i32.load (i32.const 000
        ;; RESULT should usually be zero, but by making it tunable I can debug stuff
        ;;: insert RESULT
      ))
    ;;: if RESULT=0
    ;; If we're returning LEN, convert it to an array size.
    (i32.sub (i32.const 000
        ;;: insert ARRAYP
      ))
    (i32.const 4)
    (i32.div_u)
    ;;: end
  )
  (export "run" (func $run))
)
