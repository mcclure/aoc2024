; Try to make IO do something

(local arg (. arg 1))
(if (not arg) (error "Missing command line argument"))
(local arg (io.open arg))
(if (not arg) (error "File does not exist"))
(local arg (arg:read "a"))
(print arg)
