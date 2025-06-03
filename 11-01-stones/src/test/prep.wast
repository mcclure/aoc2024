;; Test the prep.py script
;; Notice pervasive use of 000 to make Sublime syntax highlighter not break
;; Try: python3 tools/prep.py src/test/prep.wast KEY1=11 KEY2=33 KEY3="<data/sample.unknown.txt>" THREE=5 -v && cat tmp/a.wast
;; Try: python3 tools/prep.py src/test/prep.wast KEY1=11 KEY2=33 KEY3="<data/sample.unknown.txt>" && cat tmp/a.wast

(module
  (data
    (i32.const 000
    ;;: insert KEY3|i32|len
    )
    ;;: insert KEY3|i32|bin
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
