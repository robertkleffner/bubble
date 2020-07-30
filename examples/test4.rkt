#lang s-exp "../bubble.rkt"

(call 'main)
(jump 'end)

(label 'main
       (closure 'ret1)
       (op-closure 'raise1 1)
       (handle 6 0 'raise!)
       (push 2)
       (escape 'raise!)
       (push 6)
       (div-i32)
       (complete)
       (push 1)
       (add-i32)
       (return))

(label 'ret1
       (push 1)
       (add-i32)
       (return))

(label 'raise1
       (find 0 0)
       (push 2)
       (sub-i32)
       (return))

(label 'end
       (nop))