#lang s-exp "../bubble.rkt"

; main =
;   handle {
;     1 raise! 3 add
;   } with {
;     raise! e => handle { 2 resume raise! sub-i32 }
;                 with {
;                   raise! x => e x resume
;                   return => 1 add
;                 }
;     return => 2 add
;   }

(call 'main)
(jump 'end)

(label 'main
       (closure 'ret1)
       (op-closure 'raise1 1)
       (handle 'aft1 0 'raise!)
       (push 1)
       (operation 'raise!)
       (push 3)
       (add-i32)
       (complete))

(label 'aft1
       (return))

(label 'raise1
       (closure 'ret2)
       (op-closure 'raise2 1 (cons 0 1))
       (handle 'aft1 0 'raise!)
       (push 2)
       (find 1 0)
       (call-continuation)
       (operation 'raise!)
       (sub-i32)
       (complete))

(label 'raise2
       (find 0 2)
       (find 0 1)
       (find 0 0)
       (tail-call-continuation))

(label 'ret2
       (push 1)
       (add-i32)
       (return))

(label 'ret1
       (push 2)
       (add-i32)
       (return))

(label 'end
       (nop))