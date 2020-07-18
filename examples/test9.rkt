#lang s-exp "../bubble.rkt"

(call 2)
(jump 30)

(closure 27)
(op-closure 11 1)
(handle 10 0 'raise!)
(push 1)
(operation 'raise!)
(push 3)
(add-i32)
(complete)

(return)

(closure 24)
(op-closure 20 1 (cons 0 1))
(handle 10 0 'raise!)
(push 2)
(find 1 0)
(call-continuation)
(operation 'raise!)
(sub-i32)
(complete)

(find 0 2)
(find 0 1)
(find 0 0)
(tail-call-continuation)

(push 1)
(add-i32)
(return)

(push 2)
(add-i32)
(return)

(nop)