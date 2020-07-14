#lang br/quicklang

(require uuid)

(provide cons)
(provide quote)

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
    (cond
      [(var-frame? f)
       (display (var-frame-vars f))]
      [(fun-frame? f)
       (display `(f ,(fun-frame-ret-instr-ptr f) ,(fun-frame-vars f)))]
      [else
       (display f)]))
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

(provide jump)
(define (jump target)
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
(define (tail-call target) (jump target))

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
    (define new-stack (drop without-ops (add1 nargs)))
    (machine
     new-stack
     (cons (mark-frame args return ops after) (machine-frames m))
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide complete)
(define (complete)
  (λ (m)
    (define h (first (machine-frames m)))
    (machine
     (machine-stack m)
     (cons (fun-frame (append (mark-frame-args h) (closure-val-captured (mark-frame-return h)))
                      (mark-frame-after-instr-ptr h))
           (rest (machine-frames m)))
     (machine-heap m)
     (machine-instrs m)
     (closure-val-body (mark-frame-return h)))))

(provide escape)
(define (escape op-name)
  (λ (m)
    (define h (find-handler (machine-frames m) op-name))
    (define op (hash-ref (mark-frame-ops h) op-name))
    (machine
     null
     (cons (fun-frame
            (append (take (machine-stack m) (op-closure-val-nargs op))
                    (op-closure-val-captured op))
            (mark-frame-after-instr-ptr h))
           (drop-to-handler (machine-frames m) op-name))
     (machine-heap m)
     (machine-instrs m)
     (op-closure-val-body op))))

(provide operation)
(define (operation op-name)
  (λ (m)
    (define h (find-handler (machine-frames m) op-name))
    (define op (hash-ref (mark-frame-ops h) op-name))
    (define cont
      (continuation
       (add1 (machine-instr-ptr m))
       (frames-to-handler (machine-frames m) op-name)
       (drop (machine-stack m) (op-closure-val-nargs op))
       (length (mark-frame-args h))))
    (machine
     null
     (cons (fun-frame
            (cons cont
                  (append (take (machine-stack m) (op-closure-val-nargs op))
                          (op-closure-val-captured op)))
            (mark-frame-after-instr-ptr h))
           (drop-to-handler (machine-frames m) op-name))
     (machine-heap m)
     (machine-instrs m)
     (op-closure-val-body op))))

(define (frames-to-handler frames op)
  (cond
    [(null? frames) (error "couldnt capture stack")]
    [(handler-with-op? (first frames) op)
     (list (first frames))]
    [else (cons (first frames) (frames-to-handler (rest frames) op))]))
       

(define (find-handler frames op)
  (cond
    [(null? frames) (error "no frame found")]
    [(handler-with-op? (first frames) op)
     (first frames)]
    [else
     (find-handler (rest frames) op)]))

(define (drop-to-handler frames op)
  (cond
    [(null? frames) (error "dropped all frames")]
    [(handler-with-op? (first frames) op)
     (rest frames)]
    [else (drop-to-handler (rest frames))]))

(define (handler-with-op? frame op)
  (and (mark-frame? frame) (hash-has-key? (mark-frame-ops frame) op)))

(provide call-continuation)
(define (call-continuation)
  (λ (m)
    (define cont (first (machine-stack m)))
    (define handler (last (continuation-captured-frames cont)))
    (define args (take (rest (machine-stack m)) (continuation-nargs cont)))
    (define new-handler
      (mark-frame args
                  (mark-frame-return handler)
                  (mark-frame-ops handler)
                  (add1 (machine-instr-ptr m))))
    (machine
     (append (drop (machine-stack m) (add1 (length args)))
             (continuation-captured-stack cont))
     (append (drop-right (continuation-captured-frames cont) 1)
             (cons new-handler (machine-frames m)))
     (machine-heap m)
     (machine-instrs m)
     (continuation-resume cont))))

(provide tail-call-continuation)
(define (tail-call-continuation)
  (λ (m)
    (define cont (first (machine-stack m)))
    (define handler (last (continuation-captured-frames cont)))
    (define args (take (rest (machine-stack m)) (continuation-nargs cont)))
    (define new-handler
      (mark-frame args
                  (mark-frame-return handler)
                  (mark-frame-ops handler)
                  (fun-frame-ret-instr-ptr (first (machine-frames m)))))
    (machine
     (append (drop (machine-stack m) (add1 (length args)))
             (continuation-captured-stack cont))
     (append (drop-right (continuation-captured-frames cont) 1)
             (cons new-handler (rest (machine-frames m))))
     (machine-heap m)
     (machine-instrs m)
     (continuation-resume cont))))



(provide shuffle)
(define (shuffle count . indices)
  (λ (m)
    (define items (take (machine-stack m) count))
    (machine
     (append (for/list ([i indices]) (list-ref items i))
             (drop (machine-stack m) count))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))



(provide jump-if)
(define (jump-if target)
  (λ (m)
    (machine
     (machine-stack m)
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (if (first (machine-stack m))
         target
         (add1 (machine-instr-ptr m))))))

(provide jump-if-not)
(define (jump-if-not target)
  (λ (m)
    (machine
     (machine-stack m)
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (if (not (first (machine-stack m)))
         target
         (add1 (machine-instr-ptr m))))))



(provide newref)
(define (newref)
  (λ (m)
    (define ref (uuid-symbol))
    (machine
     (cons ref (rest (machine-stack m)))
     (machine-frames m)
     (hash-set (machine-heap m) ref (first (machine-stack m)))
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide getref)
(define (getref)
  (λ (m)
    (machine
     (cons (hash-ref (machine-heap m) (first (machine-stack m))) (machine-stack m))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(provide putref)
(define (putref)
  (λ (m)
    (machine
     (rest (machine-stack m))
     (machine-frames m)
     (hash-set (machine-heap m) (second (machine-stack m)) (first (machine-stack m)))
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

        



(provide bool-and)
(define (bool-and)
  (binary-instr (λ (l r) (and l r))))

(provide bool-or)
(define (bool-or)
  (binary-instr (λ (l r) (or l r))))

(provide bool-not)
(define (bool-not)
  (unary-instr not))

(provide add-i32)
(define (add-i32)
  (binary-instr +))

(provide sub-i32)
(define (sub-i32)
  (binary-instr -))

(provide mul-i32)
(define (mul-i32)
  (binary-instr *))

(provide div-i32)
(define (div-i32)
  (binary-instr /))

(define (unary-instr op)
  (λ (m)
    (define old-stack (machine-stack m))
    (machine
     (cons (op (car old-stack)) (cdr old-stack))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))

(define (binary-instr op)
  (λ (m)
    (define old-stack (machine-stack m))
    (machine
     (cons (op (car old-stack) (cadr old-stack)) (cddr old-stack))
     (machine-frames m)
     (machine-heap m)
     (machine-instrs m)
     (add1 (machine-instr-ptr m)))))