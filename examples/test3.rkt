#lang s-exp "../bubble.rkt"

; main =
;   2 handle {
;     2 4 add-i32
;   } with {
;     return => 1 add-i32
;   }
;   sub

(call 'main)
(jump 'end)

(label 'main
       (push 2)
       (closure 'ret1)
       (handle 5 0)
       (push 2)
       (push 4)
       (add-i32)
       (complete)
       (sub-i32)
       (return))

(label 'ret1
       (push 1)
       (add-i32)
       (return))

(label 'end
       (nop))