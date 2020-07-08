#lang br/quicklang

;; frame = instr-ptr + list value

(struct machine
  (stack ;; list value
   frames ;; list vars|frame|handler
   heap   ;; hash-table guid value
   instrs ;; list function
   instr-ptr)
  #:transparent)

(struct var-frame
  (vars)
  #:transparent)

(struct fun-frame
  (vars
   ret-instr-ptr)
  #:transparent)

(struct handler
  (vars
   args
   ret-instr-ptr
   ops)
  #:transparent)

(define (value-in-frame machine frame-ind value-ind)
  (define frame (list-ref (machine-frames machine) frame-ind))
  (define varlist
    (cond
      [(var-frame? frame)
       (var-frame-vars frame)]
      [(fun-frame? frame)
       (fun-frame-vars frame)]
      [(handler? frame)
       (handler-vars frame)]))
  (list-ref varlist value-ind))

(struct closure-val
  (body
   captured)
  #:transparent)

(struct op-closure-val
  (body
   captured
   op-id
   nargs)
  #:transparent)

(define-macro (tea-vm-mb EXPR ...)
  #'(#%module-begin
     (define res
       (run
        (machine
         (list)
         (list)
         (make-immutable-hash)
         (list EXPR ...)
         0)))
     (displayln (machine-stack res))))

(provide (rename-out [tea-vm-mb #%module-begin]))

(define (run m)
  (define iptr (machine-instr-ptr m))
  (cond
    [(< iptr (length (machine-instrs m)))
     (define instr (list-ref (machine-instrs m) iptr))
     (run (instr m))]
    [else m]))

(provide push-value)
(define (push-value val)
  (lambda (m)
    (machine
     (cons val (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide zap-value)
(define (zap-value offset-from-top)
  (lambda (m)
    (machine
     (let-values ([(left right) (split-at (machine-stack m) offset-from-top)])
       (append left (rest right)))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide add-i32)
(define (add-i32)
  (lambda (m)
    (define old-stack (machine-stack m))
    (machine
     (cons (+ (car old-stack) (cadr old-stack)) (cddr old-stack))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide goto)
(define (goto ptr)
  (lambda (m)
    (machine
     (machine-stack m)
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     ptr)))

(provide branch-true)
(define (branch-true if-true)
  (lambda (m)
    (rest (machine-stack m))
    (machine-frames m)
    (machine-heap m)
    (machine-instrs m)
    (if (first (machine-stack m))
        if-true
        (add1 (machine-instr-ptr m)))))

(provide branch-zero)
(define (branch-zero if-zero)
  (lambda (m)
    (rest (machine-stack m))
    (machine-frames m)
    (machine-heap m)
    (machine-instrs m)
    (if (zero? (first (machine-stack m)))
        if-zero
        (add1 (machine-instr-ptr m)))))



(provide return-expr)
(define (return-expr)
  (lambda (m)
    (define current-frame (first (machine-frames m)))
    (machine
     (machine-stack m)
     (rest (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (car current-frame))))

(provide call)
(define (call)
  (lambda (m)
    (define called (first (machine-stack m)))
    (machine
     (rest (machine-stack m))
     (cons (cons (add1 machine-instr-ptr m) (closure-val-captured called))
           (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (closure-val-body called))))

(provide tail-call)
(define (tail-call)
  (lambda (m)
    (define called (first (machine-stack m)))
    (define previous (first (machine-frames m)))
    (machine
     (rest (machine-stack m))
     (cons (cons (car previous) (closure-val-captured called))
           (rest (machine-frames m)))
     (machine-heap m)
     (machine-instrs m)
     (closure-val-body called))))



(provide store-frame)
(define (store-frame nvars)
  (lambda (m)
    (machine
     (drop (machine-stack m) nvars)
     (cons (take (machine-stack m) nvars)
           (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide drop-frame)
(define (drop-frame)
  (lambda (m)
    (machine
     (machine-stack m)
     (rest (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide get-var)
(define (get-var frame-ind var-ind)
  (lambda (m)
    (machine
     (cons (value-in-frame m frame-ind var-ind) (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))



(provide closure)
(define (closure body vars ...)
  (lambda (m)
    (define captured
      (for/list ([p vars])
        (value-in-frame m (car p) (cdr p))))
    (machine
     (cons (closure-val body captured) (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide op-closure)
(define (op-closure op-id body nargs vars ...)
  (lambda (m)
    (define captured
      (for/list ([p vars])
        (value-in-frame m (car p) (cdr p))))
    (machine
     (cons (op-closure-val body captured op-id nargs) (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))