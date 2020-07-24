#lang s-exp "../bubble.rkt"

; main =
;   handle {
;     3 4 raise! 6 div
;   } with {
;     raise! e => 2 e sub resume
;     return => 1 add
;   }

(call 'main)
(jump 'end)

(label 'main
       (closure 'ret1)
       (op-closure 'raise1 1)
       (handle 'aft1 0 'raise!)
       (push 3)
       (push 4)
       (operation 'raise!)
       (push 6)
       (div-i32)
       (complete))

(label 'aft1
       (add-i32)
       (return))

(label 'raise1
       (push 2)
       (find 0 1)
       (sub-i32)
       (find 0 0)
       (tail-call-continuation))

(label 'ret1
       (push 1)
       (add-i32)
       (return))

(label 'end
       (nop))