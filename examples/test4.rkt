#lang s-exp "../bubble.rkt"

(call 2)
(jump 20)

(closure 17)
(op-closure 13 1)
(handle 10 0 'raise!)
(push 2)
(escape 'raise!)
(push 6)
(div-i32)
(complete)

(push 1)
(add-i32)
(return)

(find 0 0)
(push 2)
(sub-i32)
(return)

(push 1)
(add-i32)
(return)

(nop)