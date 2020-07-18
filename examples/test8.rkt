#lang s-exp "../bubble.rkt"

(call 2)
(jump 34)

(push 2)
(closure 18)
(op-closure 14 1)
(op-closure 10 0)
(handle 9 1 'get! 'put!)
(call 24)
(complete)

(return)

(find 0 1)
(find 0 1)
(find 0 0)
(tail-call-continuation)

(list-nil)
(find 0 1)
(find 0 0)
(tail-call-continuation)

(list-nil)
(shuffle 2 1 0)
(list-cons)
(find 0 0)
(list-cons)
(return)

(operation 'get!)
(push 1)
(add-i32)
(operation 'put!)
(shuffle 1)
(operation 'get!)
(push 1)
(add-i32)
(operation 'put!)
(return)

(nop)