#lang s-exp "../tea-two.rkt"

(call 2)
(jump 26)

(closure 22)
(op-closure 10 0)
(handle 9 0 'flip!)
(operation 'flip!)
(operation 'flip!)
(bool-xor)
(complete)

(return)

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
(return)

(list-nil)
(shuffle 2 1 0)
(list-cons)
(return)

(nop)