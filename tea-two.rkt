#lang br/quicklang

(provide cons)

(struct machine
  (stack ;; list value
   frames ;; list vars|frame|mark
   heap   ;; hash guid value
   instrs ;; list function
   instr-ptr ;; int
   )
  #:transparent)

(define (print-machine m)
  (display (machine-stack m))
  (print-frames (machine-frames m))
  (display (machine-heap m))
  (displayln (machine-instr-ptr m)))

(define (print-frames fs)
  (display "(")
  (for ([f fs])
    (display "(")
    (cond
      [(var-frame? f)
       (display (var-frame-vars f))]
      [(fun-frame? f)
       (display `(f ,(fun-frame-ret-instr-ptr f) ,(fun-frame-vars f)))]
      [else
       (display f)])
    (display ")"))
  (display ")"))

(struct var-frame
  (vars)
  #:transparent)

(struct fun-frame
  (vars ;; list value
   ret-instr-ptr ;; int
   )
  #:transparent)

(struct mark-frame
  (args ;; list value
   return ;; closure-val
   ops ;; hash int op-closure-val
   after-instr-ptr ;; int
   )
  #:transparent)

(define (value-in-frame machine frame-ind value-ind)
  (define frame (list-ref (machine-frames machine) frame-ind))
  (define varlist
    (cond
      [(var-frame? frame)
       (var-frame-vars frame)]
      [(fun-frame? frame)
       (fun-frame-vars frame)]
      [(mark-frame? frame)
       (mark-frame-args frame)]))
  (list-ref varlist value-ind))

(struct closure-val
  (body ;; int
   captured ;; list value
   )
  #:transparent
  #:mutable)

(struct op-closure-val
  (body ;; int
   captured ;; list value
   nargs ;; int
   )
  #:transparent)

(struct continuation
  (resume ;; int
   captured-frames ;; list frame
   captured-stack ;; list value
   nargs ;; int
   )
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
  (print-machine m)
  (define iptr (machine-instr-ptr m))
  (cond
    [(< iptr (length (machine-instrs m)))
     (define instr (list-ref (machine-instrs m) iptr))
     (run (instr m))]
    [else m]))



(provide nop)
(define (nop)
  (λ (m)
    (machine
     (machine-stack m)
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide push)
(define (push v)
  (λ (m)
    (machine
     (cons v (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide goto)
(define (goto target)
  (λ (m)
    (machine
     (machine-stack m)
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     target)))

(provide return)
(define (return)
  (λ (m)
    (define target (first (machine-frames m)))
    (machine
     (machine-stack m)
     (rest (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (fun-frame-ret-instr-ptr target))))

(provide call)
(define (call target)
  (λ (m)
    (machine
     (machine-stack m)
     (cons (fun-frame (list) (add1 (machine-instr-ptr m)))
           (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     target)))

(provide tail-call)
(define (tail-call target) (goto target))

(provide store)
(define (store count)
  (λ (m)
    (machine
     (drop (machine-stack m) count)
     (cons (var-frame (take (machine-stack m) count)) (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide forget)
(define (forget)
  (λ (m)
    (machine
     (machine-stack m)
     (rest (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide find)
(define (find frame-ind var-ind)
  (lambda (m)
    (machine
     (cons (value-in-frame m frame-ind var-ind) (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide call-closure)
(define (call-closure)
  (λ (m)
    (define fn (first (machine-stack m)))
    (machine
     (rest (machine-stack m))
     (cons (fun-frame (closure-val-captured fn) (add1 (machine-instr-ptr m)))
           (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (closure-val-body fn))))

(provide tail-call-closure)
(define (tail-call-closure)
  (λ (m)
    (define fn (first (machine-stack m)))
    (machine
     (rest (machine-stack m))
     (cons (fun-frame (closure-val-captured fn) (fun-frame-ret-instr-ptr (first (machine-frames m))))
           (rest (machine-frames m)))
     (machine-heap m)
     (machine-instrs m)
     (closure-val-body fn))))

(provide closure)
(define (closure body . vars)
  (λ (m)
    (define captured
      (for/list ([p vars])
        (value-in-frame m (car p) (cdr p))))
    (machine
     (cons (closure-val body captured) (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide recursive)
(define (recursive body . vars)
  (λ (m)
    (define captured
      (for/list ([p vars])
        (value-in-frame m (car p) (cdr p))))
    (define closed (closure-val body captured))
    (set-closure-val-captured! closed (cons closed captured))
    (machine
     (cons closed (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))



(provide op-closure)
(define (op-closure body nargs . vars)
  (λ (m)
    (define captured
      (for/list ([p vars])
        (value-in-frame m (car p) (cdr p))))
    (machine
     (cons (op-closure-val body captured nargs) (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide handle)
(define (handle after nargs . op-ids)
  (λ (m)
    (define ops
      (for/hash ([id op-ids]
                 [op-c (machine-stack m)])
        (values id op-c)))
    (define without-ops (drop (machine-stack m) (length op-ids)))
    (define return (first without-ops))
    (define args (take (rest without-ops) nargs))
    (define new-stack (drop (add1 nargs)))
    (machine
     new-stack
     (cons (mark-frame args return ops after) (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide complete)
(define (complete)
  (λ (m)
    ))
        



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
