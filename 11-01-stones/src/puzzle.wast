;; AOC day 11 part 1
;; Note: First 24 bytes of memory reserved for nonsense reasons

;; set 

(module
;;: if DEBUG
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (func $putc (param $in i32)
      ;; Creating a new io vector within linear memory
      (i32.store (i32.const 0) (i32.const 8))  ;; iov.iov_base - This is a pointer to the start of the 'hello world\n' string
      (i32.store (i32.const 4) (i32.const 1))  ;; iov.iov_len - The length of the 'hello world\n' string
      (i32.store8 (i32.const 20) (local.get $in))

      (call $fd_write
          (i32.const 1) ;; file_descriptor - 1 for stdout
          (i32.const 0) ;; *iovs - The pointer to the iov array, which is stored at memory location 0
          (i32.const 1) ;; iovs_len - We're printing 1 string stored in an iov - so one.
          (i32.const 12) ;; nwritten - A place in memory to store the number of bytes written
      )
      drop ;; Discard the number of bytes written from the top of the stack
  )
  (func $putsp
    (i32.const 20)
    call $putc
  )
  (func $putlf
    (i32.const 10)
    call $putc
  )
  (func $puti (param $in i32) (local $digits i32) (local $chp i32)
    (local.set $digits (i32.const 0))
    (local.set $chp (i32.const 20))
    (block $atoi
      local.get $digits  i32.const 1  i32.add  local.get $chp  memory.store32
      local.get $in  i32.const 10  i32.idiv_u  memory.store8 $chp
;;      (memory.store8 $chp (i32.irem_u  ))
;;      (memory.store32 $digits (i32.add $digits i32.const 1))
 ;;     (memory.store32 $in (i32.idiv_u $in 10))
      (if (i32.ieq(digits i32.const 0)))
      )
    (i32.store (i32.const 0) ($len))  ;; iov.iov_base - This is a pointer to the start of the 'hello world\n' string
      (i32.store (i32.const 4) ($digits))  ;; iov.iov_len - The length of the 'hello world\n' string
      (i32.store8 (i32.const 20) (local.get $in))

      (call $fd_write
          (i32.const 1) ;; file_descriptor - 1 for stdout
          (i32.const 0) ;; *iovs - The pointer to the iov array, which is stored at memory location 0
          (i32.const 1) ;; iovs_len - We're printing 1 string stored in an iov - so one.
          (i32.const 12) ;; nwritten - A place in memory to store the number of bytes written
      )
      drop ;; Discard the number of bytes written from the top of the stack

;;    (local.get $in)

  )
;;: end

  (data
    (i32.const 000
    ;;: insert INPUT|i32|len
    )
    ;;: insert INPUT|i32|bin
  )
  (func $add (result i32)
    ;;: if TWO
      i32.const 2
      i32.const 2
    ;;: elseif THREE=5
      i32.const 5
      i32.const 5
    ;;: elseif THREE=1
      i32.const 3
      i32.const 3
    ;;: else
      i32.const 000
      ;;: insert KEY1
      i32.const 000
      ;;: insert KEY2
    ;;: end
    i32.add)
  (export "add" (func $add))
)
