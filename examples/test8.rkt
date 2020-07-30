#lang s-exp "../bubble.rkt"

; main =
;   let counter = get! 1 add-i32 put! zap get! 1 add put!
;   2
;   handle s { counter }
;   with {
;     get! => s s resume
;     put! n => [] n resume
;     return => [] swap cons s cons
;   }

(call 'main)
(jump 'end)

(label 'main
       (push 2)
       (closure 'ret1)
       (op-closure 'put1 1)
       (op-closure 'get1 0)
       (handle 3 1 'get! 'put!)
       (call 'counter)
       (complete)
       (return))

(label 'get1
       (find 0 1)
       (find 0 1)
       (find 0 0)
       (tail-call-continuation))

(label 'put1
       (list-nil)
       (find 0 1)
       (find 0 0)
       (tail-call-continuation))

(label 'ret1
       (list-nil)
       (shuffle 2 1 0)
       (list-cons)
       (find 0 0)
       (list-cons)
       (return))

(label 'counter
       (operation 'get!)
       (push 1)
       (add-i32)
       (operation 'put!)
       (shuffle 1)
       (operation 'get!)
       (push 1)
       (add-i32)
       (operation 'put!)
       (return))

(label 'end
       (nop))