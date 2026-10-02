;; AOC day 11 part 1
;; python3 tools/prep.py src/puzzle.wast INPUT="<data/sample.55312.txt>" MEMORY=1 ROUNDS=25 RESULT=0

;;  MAX_UINT/2024
;;: set WILL_OVERFLOW_OVER=2122019

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
  (func $unshift (param $idx i32) (param $new i32) (local $max i32)
    (i32.const 000
        ;;: insert LENP
    )
    (i32.const 000
        ;;: insert LENP
    )
    (i32.load)
    (local.tee $max) ;; old len is new final index
    (i32.add (i32.const 4))
    (i32.store)

    (loop $copy
      (local.get $idx) ;; a
      (i32.const 4)    ;; 1
      (i32.add)        ;; b = a + 1
      (local.tee $idx) ;; $idx = clone(b) [ $idx = $idx + 1 ]
      (local.get $new) ;; c = $new
      (local.get $idx) ;; d = $idx
      (i32.load)       ;; e = *d
      (local.set $new) ;; $new = e        [ $new = *$idx ]
      (i32.store)      ;; *b = old(c)     [ *$idx = old($new )]
      (local.get $max)
      (local.get $idx)
      (i32.gt_u)
      (br_if $copy)
    )
  )
  (func $run (result i32) (local $pass i32) (local $idx i32)
      (local $current i32) (local $tcurrent i32) (local $tdivider i32)
      ;;(local $debug i32)
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
          (local.tee $current)
          (if
            (then ;; Number was nonzero
              (local.set $tdivider (i32.const 1))
              (local.set $tcurrent (local.get $current))
              (loop $modulo
                (local.get $tcurrent)
                (i32.const 10)
                (i32.div_u)
                (local.tee $tcurrent)

                (if
                  (then ;; at least one more digit
                    (local.get $tdivider)
                    (i32.const 10)
                    (i32.mul)
                    (local.set $tdivider)

                    (local.get $tcurrent)
                    (i32.const 10)
                    (i32.div_u)
                    (local.tee $tcurrent)

                    (if
                      (then ;; at least one more digit...
                        (br $modulo)
                      )
                      (else ;; Even digits!!!
                        (local.get $idx)
                        (local.get $current)
                        (local.get $tdivider)
                        (i32.div_u)
                        (i32.store)
                        (local.get $idx)
                        (local.get $current)
                        (local.get $tdivider)
                        (i32.rem_u)
                        (call $unshift)
                      )
                    )
                  )
                  (else ;; oops, we just proved odd digits
                    (local.get $current)
                    (i32.const 000 ;; real quick, test safety
                      ;;: insert WILL_OVERFLOW_OVER
                    )
                    (i32.gt_u) ;; I hate the ordering here
                    (if
                      (then unreachable)
                      (else ;; Safe to multiply
                        (local.get $idx)
                        (local.get $current)
                        (i32.const 2024)
                        (i32.mul)
                        (i32.store)
                      )
                    )
                  )
                )
              )
            )
            (else ;; Number was 0
              (local.get $idx)
              (i32.const 1)
              i32.store
            )
          )

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

    ;; drop (local.get $debug) ;; uncomment to debug
  )
  (export "run" (func $run))
)
