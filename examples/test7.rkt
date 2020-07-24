#lang s-exp "../bubble.rkt"

(call 'main)
(jump 'end)

(label 'main
       (push 2)
       (closure 'ret1)
       (handle 'aft1 1)
       (push 1)
       (complete))

(label 'aft1
       (return))

(label 'ret1
       (list-nil)
       (shuffle 2 1 0)
       (list-cons)
       (find 0 0)
       (list-cons)
       (return))

(label 'end
       (nop))