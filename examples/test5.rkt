#lang s-exp "../bubble.rkt"

(call 2)
(jump 21)

(closure 18)
(op-closure 13 1)
(handle 11 0 'raise!)
(push 3)
(push 4)
(operation 'raise!)
(push 6)
(div-i32)
(complete)

(add-i32)
(return)

(push 2)
(find 0 1)
(sub-i32)
(find 0 0)
(tail-call-continuation)

(push 1)
(add-i32)
(return)

(nop)