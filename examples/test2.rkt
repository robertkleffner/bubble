#lang s-exp "../bubble.rkt"

(call 2)
(jump 19)

(push 1)
(push 2)
(store 2)
(closure 17 (cons 0 1))
(store 1)
(find 1 0)
(push 3)
(store 1)
(find 1 0)
(call-closure)
(add-i32)
(forget)
(forget)
(forget)
(return)

(find 0 0)
(return)

(nop)