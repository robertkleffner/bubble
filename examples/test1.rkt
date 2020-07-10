#lang s-exp "../tea-two.rkt"

(call 2)
(goto 9)

(tail-call 3)

(call 7)
(push 2)
(add-i32)
(return)

(push 1)
(return)

(nop)