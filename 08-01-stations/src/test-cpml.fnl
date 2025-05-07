; fennel --add-package-path "cpml/modules/?.lua" src/test-cpml.fnl

(local vec2 (require :vec2))

(var v (vec2 3 3))

(set v (+ v (vec2 1 -1)))

(print v)
