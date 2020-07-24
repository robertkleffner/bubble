#lang s-exp "../bubble.rkt"

; main = 1 2
;   vars x y in
;     let z = y in
;     x 3 vars y in z add-i32

(call 'main)
(jump 'end)

(label 'main
       (push 1)
       (push 2)
       (store 2)
       (closure 'z (cons 0 1))
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
       (return))

(label 'z
       (find 0 0)
       (return))

(label 'end
       (nop))