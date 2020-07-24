#lang s-exp "../bubble.rkt"

; main =
;   let x = 1 in
;   let y = x 2 add-i32 in
;   y

(call 'main)
(jump 'end)

(label 'main
       (tail-call 'y))

(label 'y
       (call 'x)
       (push 2)
       (add-i32)
       (return))

(label 'x
       (push 1)
       (return))

(label 'end
       (nop))