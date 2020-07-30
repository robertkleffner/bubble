#lang s-exp "../bubble.rkt"

; main =
;   handle {
;     flip! flip! xor
;   } with {
;     flip! => false resume vars x in { true resume x swap append }
;     return => [] swap cons
;   }

(call 'main)
(jump 'end)

(label 'main
       (closure 'ret1)
       (op-closure 'flip1 0)
       (handle 5 0 'flip!)
       (operation 'flip!)
       (operation 'flip!)
       (bool-xor)
       (complete)
       (return))

(label 'flip1
       (push #f)
       (find 0 0)
       (call-continuation)
       (store 1)
       (push #t)
       (find 1 0)
       (call-continuation)
       (find 0 0)
       (shuffle 2 1 0)
       (list-append)
       (forget)
       (return))

(label 'ret1
       (list-nil)
       (shuffle 2 1 0)
       (list-cons)
       (return))

(label 'end
       (nop))