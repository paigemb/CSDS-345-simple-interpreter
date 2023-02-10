; Paige Biggs, Akhila Vuppalapati, Amy Yu
#lang racket
(require "simpleParser.rkt")

; Takes a filename, calls parser with the filename, passes to M-state-statement list to evaluate the syntax tree returned by the parser
(define interpret
  (lambda (filename)
    (M-state-statement-list (parser filename) (initialize-empty-state))))

; Takes the statement list and a state
; Returns the current state
(define M-state-statement-list 
  (lambda (statement-list state)
    (if (null? statement-list)
        state
        (M-state-statement-list (cdr statement-list) (M-state (car statement-list) state)))))
 
; return empty state
(define initialize-empty-state
  (lambda ()
    '(()())))

; define M-state 
; list with two sublists, one with the variables and one with the values (for example: ((x y ...) (5 12 ...)))
(define M-state
  (lambda (statement state)
    (M-state-statement statement state)))
    
; Abstractions for state
; Function to return the variable name sublist
(define M-state-vars 
  (lambda (state)
    (car state)))

; Function to return value sublist
(define M-state-values 
  (lambda (state)
    (cadr state)))

; Returns the variable name from the statement 
(define statement-var cadr)
; Returns the variable value from the statement 
(define statement-val caddr) 

; Called on declaration statements (var), takes a statement and a state and updates the state
; Assigns 'unassigned' to values that are declared without assignment
(define M-state-declare 
  (lambda (statement state) 
    (cond
      ; checks if variable is already declared
      ((M-declared-list-lookup (statement-var statement) (M-state-vars state)) (error "Variable already declared"))
      ; variable declared with assignment 
      ((= 3 (length statement)) (M-state-assign (statement-var statement) (M-value (rightoperand statement) state) (M-state-declare (list (car statement) (cadr statement)) state))) 
      ; variable is only declared
      ((= 2 (length statement)) (M-state-add (statement-var statement) 'unassigned state)))))

; Takes a variable and the sublist of declared variables and checks to see if the variable has been declared or not
(define M-declared-list-lookup 
  (lambda (var declared-list)
    (cond
      ((null? declared-list) #f)
      ((eq? var (car declared-list)) #t)
      (else (M-declared-list-lookup var (cdr declared-list))))))

; Takes a variable and the state and returns the variable's corresponding value in M-state
(define M-state-lookup
  (lambda (var state)
    (cond
      ((null? state) (error "Using before declaring or assigning"))
      ((null? (M-state-vars state)) (error "Using before declaring or assigning"))
      ((eq? var (car (M-state-vars state))) (car (M-state-values state)))
      (else (M-state-lookup var (append (list (cdr (M-state-vars state))) (list (cdr (M-state-values state)))))))))

; Takes a variable, value, and state, assigns the variable a value and updates the state
(define M-state-assign
  (lambda (var val state)
    (cond
      ((eq? (M-state-lookup var state) 'unassigned) (M-state-add var val (M-state-remove var state)))
      ((M-declared-list-lookup var (M-state-vars state)) (M-state-add var val (M-state-remove var state)))
      (else (error "Using variable before declaring or assigning")))))

; Takes a variable, value, and state and updates the state with a new binding
(define M-state-add
  (lambda (var val state)
    (append (list (append (M-state-vars state) (list var))) (list (append (M-state-values state) (list val))))))

; Takes a variable and state, removes the variable and its corresponding value from the state
(define M-state-remove
  (lambda (var state) 
    (cond
      ((null? (car state)) state) 
      ((equal? var (car (M-state-vars state))) (append (list (cdr (M-state-vars state))) (list (cdr (M-state-values state)))))
      (else (M-state-remove var (M-state-remove-helper state))))))

; Helper method for the remove method
; Used for preserving the previous bindings before the removed one
(define M-state-remove-helper
  (lambda (state)
    (if (null? state)
        (error "Need state as a parameter")
        (append (list (append (cdr (M-state-vars state)) (list (caar state)))) (list (append (cdr (M-state-values state)) (list (caadr state))))))))

; Abstractions
; Returns operator of expression
(define operator (lambda (expression) (car expression)))
; Returns left operand of expression
(define leftoperand cadr)
; Returns right operand of expression
(define rightoperand caddr)

; Function to handle unary operators (- and !)
(define unary-op
  (lambda (expression state)
    (cond
      ((eq? (operator expression) '-) (* (- 1) (M-value (leftoperand expression) state)))
      ((eq? (operator expression) '!) (not (M-value (leftoperand expression) state))))))

; Takes an expression and state and returns the integer value of the expression
(define M-integer
  (lambda (expression state)
    (cond
      ((number? expression) expression)
      ((M-declared-list-lookup expression (M-state-vars state)) (M-state-lookup expression state))
      ((= 2 (length expression)) (unary-op expression state))
      ((eq? (operator expression) '+) (+ (M-integer (leftoperand expression) state) (M-integer (rightoperand expression) state)))
      ((eq? (operator expression) '-) (- (M-integer (leftoperand expression) state) (M-integer(rightoperand expression) state)))
      ((eq? (operator expression) '*) (* (M-integer (leftoperand expression) state) (M-integer (rightoperand expression) state)))
      ((eq? (operator expression) '/) (quotient (M-integer (leftoperand expression) state) (M-integer (rightoperand expression) state)))
      ((eq? (operator expression) '%) (remainder (M-integer (leftoperand expression) state) (M-integer (rightoperand expression) state)))
      (else (error "bad operator")))))

; Takes an expression and state and returns the boolean value of the expression
(define M-boolean
  (lambda (expression state)
    (cond
      ((eq? 'true expression) #t)
      ((eq? 'true expression) #f)
      ((M-declared-list-lookup expression (M-state-vars state)) (M-state-lookup expression state))
      ((eq? (operator expression) '>) (> (M-value (leftoperand expression) state) (M-value (rightoperand expression) state)))
      ((eq? (operator expression) '<) (< (M-value (leftoperand expression) state) (M-value (rightoperand expression) state)))
      ((eq? (operator expression) '>=) (>= (M-value (leftoperand expression) state) (M-value (rightoperand expression) state)))
      ((eq? (operator expression) '<=) (<= (M-value (leftoperand expression) state) (M-value (rightoperand expression) state)))
      ((eq? (operator expression) '==) (eq? (M-value (leftoperand expression) state) (M-value (rightoperand expression) state)))
      ((eq? (operator expression) '!=) (not (eq? (M-value (leftoperand expression) state) (M-value (rightoperand expression) state))))
      ((eq? (operator expression) '&&) (and (M-value (leftoperand expression) state) (M-value (rightoperand expression) state)))
      ((eq? (operator expression) '||) (or (M-value (leftoperand expression) state) (M-value (rightoperand expression) state)))
      (else (error "bad operator")))))

; Takes condition, body, and state and executes while loop body
(define M-state-while
  (lambda (condition body state)
    (if (M-boolean condition state)
        (M-state-while condition body (M-state-statement body state))
        state)))

; Abstractions
; Returns the type of statement (if, while, assign, declaration, etc.)
(define statement-type
  (lambda (statement)
    (car statement)))

; Returns the condition for the if and while 
(define statement-condition
  (lambda (expression)
    (car (cdr expression))))

; Returns the first if statmement
(define if-statement1
  (lambda (expression)
    (car (cdr (cdr expression)))))

; Returns else statement if there is one, empty list if not
(define if-statement2
  (lambda (expression)
    (if (null? (cdr (cdr (cdr expression)))) 
        '()
        (car (cdr (cdr (cdr expression)))))))

; Returns the updated state after a statement is evaluated
(define M-state-statement 
  (lambda (statement state)
    (cond
      ((eq? (statement-type statement) 'var) (M-state-declare statement state)) 
      ((eq? (statement-type statement) '=) (M-state-assign (leftoperand statement) (M-value (rightoperand statement) state) state))
      ((eq? (statement-type statement) 'if) (M-state-if statement state))
      ((eq? (statement-type statement) 'while) (M-state-while (statement-condition statement) (rightoperand statement) state))
      ((eq? (statement-type statement) 'return) (M-state-return statement state))
      (else (error "Statement type is currently not supported")))))

; Takes in an if statement and state, evaluates if the condition is true or not and returns the correct statement
(define M-state-if
  (lambda (statement state)
    (cond
      ((and (not (eq? '() (if-statement2 statement))) (M-value (statement-condition statement) state)) (M-state-statement (if-statement1 statement) state))
      ((and (not (eq? '() (if-statement2 statement))) (not (M-value (statement-condition statement) state))) (M-state-statement (if-statement2 statement) state))
      ((and (eq? '() (if-statement2 statement)) (M-value (statement-condition statement) state)) (M-state-statement (if-statement1 statement) state))
      (else state))))

; Function to tell whether a parameter is an atom or not, used for distinguishing variables 
(define (atom? x)
  (and (not (null? x))
       (not (pair? x))))

; Takes a statement and a state and returns the value of the inputed statement
(define M-value
  (lambda (statement state)
    (cond
      ((number? statement) statement)
      ((or (eq? statement 'true) (eq? statement 'false)) (M-boolean statement state))
      ((and (atom? statement) (eq? (M-state-lookup statement state) 'unassigned)
            (not (eq? statement 'true)) (not (eq? statement 'false))) (error "Using variable before assigned"))
      ((and (atom? statement) (not (eq? (M-state-lookup statement state) 'unassigned))
            (not (eq? statement 'true)) (not (eq? statement 'false))) (M-state-lookup statement state))
      ((or (eq? (operator statement) '>) (eq? (operator statement) '<) (eq? (operator statement) '>=)
           (eq? (operator statement) '<=) (eq? (operator statement) '==) (eq? (operator statement) '!=)
                                    (eq? (operator statement) '&&) (eq? (operator statement) '||)) (M-boolean statement state))
      ((= 2 (length statement)) (unary-op statement state)) 
      ((or (eq? (operator statement) '+) (eq? (operator statement) '-) (eq? (operator statement) '*)
                                      (eq? (operator statement) '/) (eq? (operator statement) '%)) (M-integer statement state))
      (else (error "no value")))))

; Handles return statements, takes an expression and a state and returns the value
(define M-state-return
  (lambda (expression state)
    (cond
      ((number? (leftoperand expression)) (leftoperand expression)) 
      ((and (atom? (leftoperand expression)) (eq? #t (M-state-lookup (leftoperand expression) state))) "true")
      ((and (atom? (leftoperand expression)) (eq? #f (M-state-lookup (leftoperand expression) state))) "false")
      ((atom? (leftoperand expression)) (M-state-lookup (leftoperand expression) state)) 
      ((eq? (M-value (cadr expression) state) #t) "true")
      ((eq? (M-value (cadr expression) state) #f) "false")
      (else (M-value (cadr expression) state)))))


      