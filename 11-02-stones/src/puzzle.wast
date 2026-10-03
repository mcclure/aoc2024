;; AOC day 11 part 1
;; python3 tools/prep.py src/puzzle.wast INPUT="<data/sample.55312.txt>" MEMORY=1 ROUNDS=25 RESULT=0
;; RESULT can be either a number or LEN

;;  MAX_UINT64/2024
;;: set WILL_OVERFLOW_OVER=9114003988986932

(module
  (global $len (mut i32) (i32.const 000
    ;;: insert INPUT|i64|len
  ))

  ;; Note to third parties. ;; followed by : invokes my preprocessor;
  ;; Instances of "000" get deleted, and are only present to make my syntax highlighter happy
  (memory 000
    ;;: insert MEMORY
  )
  (data
    (i32.const 0)
    ;; Global ARRAY: Start of data array
    ;;: set ARRAYP=0
    ;;: insert INPUT|i64|bin
  )

  ;; Memory is packed as an array of 8-byte numbers followed by 4-byte next pointers
  ;; 0 indicates the end of the linked list (safe because nodes can't be deleted and we don't want loops)
  (func $prepare_mem (local $from i32) (local $to i32) (local $last i32)
    (global.get $len)
    (local.tee $from)
    (i32.div_u (i32.const 8))
    (i32.mul (i32.const 12))
    (local.tee $to)
    (global.set $len)
    (i32.const 0)
    (local.set $last)

    (loop $prepare
      (local.get $to)           ;; a = $to
      (i32.sub (i32.const 12))  ;; b = a - 12
      (local.set $to)           ;; $to = clone($b)
      (block $copy_number
        (local.get $to)
        (i32.eq (i32.const 0))
        (br_if $copy_number)

        (local.get $to)
        (local.get $from)         ;; c = $from
        (i32.sub (i32.const 8))   ;; d = c - 8
        (local.tee $from)         ;; $from = clone(d)
        (i64.load)                ;; e = *d          [[ e = *($from - 8) ]]
        (i64.store)               ;; *b = e          [[ *(to - 12) = *($from - 8) ]]
      )
      (local.get $to)           ;; f = $to         [[ ---------- ]]
      (i32.add (i32.const 8))   ;; g = f + 8
      (local.get $last)         ;; h = $last
      (i32.store)               ;; *g = h          [[ *(new(to) + 8) = $last ]]
      (local.get $to)           ;; i = $to
      (local.tee $last)         ;; $last = i       [[ $last = new(to) ]]
      (br_if $prepare)
    )
  )

  (func $unshift (param $idx i32) (param $new i64) (local $next i32)
    (local.get $idx)
    (i32.add (i32.const 8))
    (i32.load)
    (local.tee $next)
    (global.get $len)
    (i32.store)
    (global.get $len)
    (local.get $new)
    (i64.store)
    (global.get $len)
    (i32.add (i32.const 8))
    (local.get $next)
    (i32.store)
    
    (global.get $len)
    (i32.add (i32.const 12))
    (global.set $len)
  )
  (func $run (result i64) (local $pass i32) (local $idx i32)
      (local $current i64) (local $tcurrent i64) (local $tdivider i64)
      ;;(local $debug i64)
    (local.set $pass (i32.const 000
        ;;: insert ROUNDS
    ))
    (call $prepare_mem)
    (block $countdown_done
      (loop $countdown
        ;; Loop always starts with $pass atop stack
        (local.get $pass)
        (i32.const 0)
        (i32.eq)
        (br_if $countdown_done)

        (local.set $idx (i32.const 000
          ;;: insert ARRAYP
        ))
        (loop $sweep
          (local.get $idx)
          (i64.load) ;; This Is The Number
          (local.tee $current)

          (i64.const 0)
          (i64.ne)
          (if
            (then ;; Number was nonzero
              (local.set $tdivider (i64.const 1))
              (local.set $tcurrent (local.get $current))
              (loop $modulo
                (local.get $tcurrent)
                (i64.const 10)
                (i64.div_u)
                (local.tee $tcurrent)

                (i64.const 0)
                (i64.ne)
                (if
                  (then ;; at least one more digit
                    (local.get $tdivider)
                    (i64.const 10)
                    (i64.mul)
                    (local.set $tdivider)

                    (local.get $tcurrent)
                    (i64.const 10)
                    (i64.div_u)
                    (local.tee $tcurrent)

                    (i64.const 0)
                    (i64.ne)
                    (if
                      (then ;; at least one more digit...
                        (br $modulo)
                      )
                      (else ;; Even digits!!!
                        (local.get $idx)
                        (local.get $current)
                        (local.get $tdivider)
                        (i64.div_u)
                        (i64.store)
                        (local.get $idx)
                        (local.get $current)
                        (local.get $tdivider)
                        (i64.rem_u)
                        (call $unshift)
                      )
                    )
                  )
                  (else ;; oops, we just proved odd digits
                    (local.get $current)
                    (i64.const 000 ;; real quick, test safety
                      ;;: insert WILL_OVERFLOW_OVER
                    )
                    (i64.gt_u) ;; I hate the ordering here
                    (if
                      (then unreachable)
                      (else ;; Safe to multiply
                        (local.get $idx)
                        (local.get $current)
                        (i64.const 2024)
                        (i64.mul)
                        (i64.store)
                      )
                    )
                  )
                )
              )
            )
            (else ;; Number was 0
              (local.get $idx)
              (i64.const 1)
              i64.store
            )
          )

          ;; Continue if that wasn't the lowest cell
          (local.get $idx)
          (i32.add (i32.const 8))
          (i32.load)
          (local.tee $idx)

          (br_if $sweep) ;; Only continue if next node nonzero
        )

        ;; Done; subtract one pass and leave on stack
        (local.get $pass)
        (i32.const 1)
        (i32.sub)
        (local.set $pass)
        (br $countdown)
      )
    )

    ;; Return requested result

    ;;: if RESULT=LEN
    ;; Access global and convert to array size
    (global.get $len)
    (i32.const 12)
    (i32.div_u)
    (i64.extend_i32_u)
    ;;: else
    (i64.load (i32.const 000
        ;; Access requested item in array
        ;;: insert RESULT
      ))
    ;;(i64.extend_i32_u)
    ;;: end

    ;; drop (local.get $debug) ;; uncomment to debug
  )
  (export "run" (func $run))
)
