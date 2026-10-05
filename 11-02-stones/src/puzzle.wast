;; AOC day 11 part 2
;; python3 tools/prep.py src/puzzle.wast INPUT="<data/sample.55312.txt>" MEMORY=65536 ROUNDS=75 RESULT=STONES
;; RESULT can be either ADDR4, ADDR8, LEN, or STONES
;; ADDR can be accompanied with ADDR=(addr)
;; Note: Has only been tested with INPUT files of at least two entries

;; Terrifying "one bucket hash table" implementation
;; For this we require the entire 4GB. We split the space into 8ths and assign it to 5 arrays:
;; u64 stone_numbers[134217728] ;; A number written on a stone.
;; u64 stone_count  [134217728] ;; How many stones with this number are there?
;; u32 stone_next1  [134217728] ;; What does this stone turn into at the end of a turn (EG which stone index)?
;; u32 stone_next2  [134217728] ;; IF the number splits-- what number (stone index) does it split to? (Otherwise SENTINEL)
;; u64 stone_pending[134217728] ;; What will stone_count be after this turn?

;; state:
;; u32 $len ;; length of table in elements (count of unique stones)
;; i64 $stones ;; number of stones overall
;; u32 $watermark ;; table index; entries below this level have been "calculated" (_next1 and _next2 are known)

;; A pass has three steps;
;; Calculate: $new_watermark = $len. All entries $watermark..$new_watermark have "the math" done, calculate their _next1 and _next2.
;; Apply: Run through 0..$new_watermark. Add stone_count[i] to stone_pending[stone_next[i]] and stone_pending[stone_next2[i]].
;; Flush: Run through 0..$new_watermark. Copy stone_pending to stone_count, rebuilding $stones along way.

;;: set SENTINEL=0xFFFFFFFF

;;: set MAXTABLE=134217727

;;: set NUMBERS=0
;;: set   COUNT=268435456
;;: set   NEXT1=536870912
;;: set   NEXT2=671088640
;;: set PENDING=805306368

;;  MAX_UINT64/2024
;;: set WILL_OVERFLOW_OVER=9114003988986932

(module
  (global $len (mut i32) (i32.const 000 ;; Note: Index, not byte
    ;;: insert INPUT|i64|len|/:8
  ))

  ;; Note to third parties. ;; followed by : invokes my preprocessor;
  ;; Instances of "000" get deleted, and are only present to make my syntax highlighter happy
  (memory 000
    ;;: insert MEMORY
  )
  (data
    (i32.const 0)
    ;;: insert INPUT|i64|bin
  )

  ;; All that needs to be done in this setup is fill stone_count with 1s
  (func $prepare_mem (local $idx i32)
    (loop $fill
      (local.get $idx)
      (i32.mul (i32.const 4))
      (i32.add (i32.const 000
        ;;: insert COUNT
      ))
      (i64.const 1)
      (i64.store)
      (local.get $idx)
      (i32.const 1)
      (i32.add)
      (local.tee $idx)
      (global.get $len)
      (i32.lt_u)
      (br_if $fill)
    )
  )

  ;; Add counts to pending
  (func $pending_ptr (param $idx i32) (param $offset i32) (result i32)
    (local.get $idx)
    (i32.mul (i32.const 4))
    (local.get $offset)
    (i32.add)
    (i32.load) ;; Stack now has index of next atop
    (i32.mul (i32.const 8))
    (i32.add (i32.const 000
      ;;: insert PENDING
    ))         ;; Stack now has pointer of next/pending atop
  )
  (func $apply_mem (param $to_watermark i32) (local $idx i32) (local $ptr i32) (local $count i64)
    (loop $apply
      (call $pending_ptr (local.get $idx) (i32.const 000
        ;;: insert NEXT1
      )) ;; Stack now has pointer of next1/pending atop
      (local.tee $ptr)
      (local.get $ptr)
      (i64.load) ;; Stack now has ptr, then value of next1/pending atop

      (local.get $idx) ;; Count index
      (i32.mul (i32.const 8))
      (i32.add (i32.const 000
        ;;: insert COUNT
      ))
      (i64.load)
      (local.tee $count)
      (i64.add)  ;; Stack now has next1/pending ptr, then next1/pending value + count value atop
      (i64.store)

      (block $next2
        (call $pending_ptr (local.get $idx) (i32.const 000
          ;;: insert NEXT2
        )) ;; Stack now has pointer of next2/pending atop
        (local.tee $ptr)
        (i32.const 000
          ;;: insert SENTINEL
        )
        (i32.eq)
        (br_if $next2) ;; If pointer is sentinel value, there is no next2

        (local.get $ptr)
        (local.get $ptr) ;; Two copies of next2/pending pointer atop stack
        (i64.load)
        (local.get $count) ;; Atop stack: next2/pending pointer, next2/pending value, count
        (i64.add)          ;; Atop stack: next2/pending pointer, next2/pending value + count
        (i64.store)
      )

      (local.get $idx)
      (i32.const 1)
      (i32.add)
      (local.tee $idx)
      (local.get $to_watermark)
      (i32.lt_u)
      (br_if $apply)
    )
  )

  (func $flush_mem (result i64) (local $idx i32) (local $ptr i32) (local $value i64) (local $stones i64)
    (loop $flush
      ;; Read and clear PENDING
      (local.get $idx)
      (i32.mul (i32.const 8))
      (i32.add (i32.const 000
        ;;: insert PENDING
      ))
      (local.tee $ptr)
      (i64.load)
      (local.set $value)
      (local.get $ptr)
      (i64.const 0)
      (i64.store)

      ;; Read and increment COUNT
      (local.get $idx)
      (i32.mul (i32.const 8))
      (i32.add (i32.const 000
        ;;: insert COUNT
      ))
      (local.tee $ptr)
      (local.get $ptr)
      (i64.load)
      (local.get $value)
      (i64.add)
      (i64.store)

      ;; Increment $stones
      (local.get $value)
      (local.get $stones)
      (i64.add)
      (local.set $stones)

      ;; Increment and test $idx
      (local.get $idx)
      (i32.const 1)
      (i32.add)
      (local.tee $idx)
      (global.get $len)
      (i32.lt_u)
      (br_if $flush)
    )
    (local.get $stones)
  )

  ;; Locate a stone, creating it if it doesn't exist. Increment PENDING by one.
  (func $find (param $stone i64) (result i32) (local $idx i32) (local $result i32)
    (block $scan_success
      (block $scan_fail
        (loop $scan
          ;; Test for end of list
          (local.get $idx)
          (global.get $len)
          (i32.ge_u)
          (br_if $scan_fail)

          (block $test ;; Test for item found
            (local.get $idx)
            (i32.mul (i32.const 8)) ;; Assume NUMBERS is always 0
            (i64.load)
            (local.get $stone)
            (i64.ne)
            (br_if $test)

            (local.get $idx)
            (local.set $result)
            (br $scan_success)
          )

          (local.get $idx) ;; Iterate
          (i32.const 1)
          (i32.add)
          (local.set $idx)
          (br $scan)
        )
      )

      ;; Item not found, must create item
      (global.get $len)
      (local.tee $result)
      (i32.mul (i32.const 4)) ;; Convert len to addr-- assume NUMBERS is always 0
      (local.get $stone)
      (i64.store) ;; Populate NUMBERS. And then we can stop because everything else defaults to 0
      (global.get $len)
      (i32.add (i32.const 1))
      (global.set $len)
    )

    (local.get $idx) ;; Note: This value is what will be returned from the function

    ;; Perform increment
    (local.get $idx)
    (i32.mul (i32.const 4))
    (i32.add (i32.const 000
      ;;: insert PENDING
    ))
    (local.tee $idx) ;; Slightly abusing the "style guide" of this program, we here use $idx as scratch to dup a ptr
    (local.get $idx)
    (i64.load)
    (i64.add (i64.const 1))
    (i64.store)
  )

  (func $next_store2 (param $current_at i32) (param $left i64) (param $right_at i32)
    (local.get $current_at)
    (i32.mul (i32.const 4))
    (i32.const 000
      ;;: insert NEXT1
    )
    (i32.add)
    (local.get $left)
    (call $find)
    (i32.store) ;; Store find result into next1[$current_at]
    (local.get $current_at)
    (i32.mul (i32.const 4))
    (i32.const 000
      ;;: insert NEXT2
    )
    (i32.add)
    (local.get $right_at)
    (i32.store)
  )

  (func $next_store1 (param $current_at i32) (param $left i64)
    (call $next_store2 (local.get $current_at) (local.get $left) (i32.const 000
      ;;: insert SENTINEL
    ))
  )

  (func $run (result i64) (local $pass i32)
      (local $watermark i32) (local $new_watermark i32) (local $stones i64)
      (local $current_at i32) (local $current i64) (local $tcurrent i64) (local $tdivider i64)
      ;;(local $debug i64)
    (call $prepare_mem)
    (local.set $pass (i32.const 000
        ;;: insert ROUNDS
    ))
    (local.set $stones (i64.extend_i32_u (global.get $len))) ;; This line only relevant when ROUNDS=0

    (block $countdown_done
      (loop $countdown
        ;; Loop always starts with $pass atop stack
        (local.get $pass)
        (i32.const 0)
        (i32.eq)
        (br_if $countdown_done)

        ;; Calculate
        (global.get $len)
        (local.set $new_watermark)

        (block $sweep_done
          (loop $sweep
            (local.get $watermark)
            (global.get $len)
            (i32.ge_u)
            (br_if $sweep_done) ;; Repeat the following until watermark = len

            (local.get $watermark)
            (i32.const 8)
            (i32.mul)
            (local.tee $current_at)
            (i64.load) ;; This Is The Number
            (local.tee $current)

            ;; Calculate what this number turns into
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
                          (local.get $current_at)  ;; current_at
                          (local.get $current)
                          (local.get $tdivider)
                          (i64.div_u)              ;; left
                          (local.get $current)
                          (local.get $tdivider)
                          (i64.rem_u)
                          (call $find)             ;; right_at
                          (call $next_store2)
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
                          (local.get $current_at)
                          (local.get $current)
                          (i64.const 2024)
                          (i64.mul)
                          (call $next_store1)
                        )
                      )
                    )
                  )
                )
              )
              (else ;; Number was 0
                (call $next_store1 (local.get $current_at) (i64.const 1))
              )
            )

            ;; Continue if that wasn't the highest cell
            (local.get $watermark)
            (i32.add (i32.const 1))
            (local.tee $watermark)
            (local.get $new_watermark)
            (i32.lt_u)
            (br_if $sweep)
          )
        )

        ;; Step 2: Apply
        (call $apply_mem (local.get $new_watermark))

        ;; Step 3: Flush
        (call $flush_mem)
        (local.set $stones)
        (local.get $new_watermark)
        (local.set $watermark)

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
    (global.get $len)
    (i64.extend_i32_u)
    ;;: elseif RESULT=STONES
    (local.get $stones)
    ;;: elseif RESULT=ADDR4
    (i32.load (i32.const 000
        ;; Access requested address in memory
        ;;: insert ADDR
      ))
    ;;: elseif RESULT=ADDR8
    (i64.load (i32.const 000
        ;; Access requested address in memory
        ;;: insert ADDR
      ))
    ;;: else
      ;;: error RESULT= not recognized. See comments at top of wast file.
    ;;: end

    ;; drop (local.get $debug) ;; uncomment to debug
  )
  (export "run" (func $run))
)
