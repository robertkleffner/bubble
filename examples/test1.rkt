#lang s-exp "../bubble.rkt"

(call 2)
(jump 9)

(tail-call 3)

(call 7)
(push 2)
(add-i32)
(return)

(push 1)
(return)

(nop)