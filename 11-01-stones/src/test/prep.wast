;; Test the prep.py script
;; Notice pervasive use of 000 to make Sublime syntax highlighter not break
;; Try: python3 tools/prep.py src/test/prep.wast A=3 B="<data/sample.unknown.txt>" && cat tmp/a.wast

(module
  (data
    (i32.const 000
    ;;: insert KEY3|len
    )
    ;;: insert KEY3|bin
  )
  (func $add (result i32)
    i32.const 000
    ;;: insert KEY1
    i32.const 000
    ;;: insert KEY2
    i32.add)
  (export "add" (func $add))
)
