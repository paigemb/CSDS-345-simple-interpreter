# CSDS-345-simple-interpreter
In this project, you are to create an interpreter for a very simple Java/C-ish language. The language has variables, assignment statements, mathematical expressions, comparison operators, boolean operators, if statements, while statements, and return statements.

ote that braces, { and }, are not implemented.

The following mathematical operations are implemented : +, -, *, /, % (including the unary -), the following comparison operators are implemented: ==, !=, <, >, <=. >=, and the following boolean operators: &&, ||, !. Variables may store values of type int as well as true and false. You do not have to detect an error if a program uses a type incorrectly (but it is not hard to add the error check). You do not have to implement short-circuit evaluation of && or ||, but you are welcome to do so.

You are to write your interpreter in Scheme using the functional programming style. For full marks, you should not use variables, only functions and parameters.

Your program should clearly distinguish, by naming convention and code organization, functions that are doing the M_state operations from ones doing the M_value and M_boolean operations. You do not have to call them M_, but your naming convention should be consistent.

You should use good style, indentation and proper commenting so that the code you submit is easy to read and understand.

A parser is provided for you called simpleParser.rkt Download simpleParser.rkt. You will also have to get the file lex.rkt Download lex.rkt. You can use the parser in your program by including the line (require "simpleParser.rkt") at the top of your homework file. The command assumes simpleParser.rkt is in the same directory as your homework file. If it is not, you will have to include the path to the file in the load command.

If you are not using racket, you should use (load "simpleParser.rkt") at the top of your file instead of the load function, and you will need to comment some lines in the simpleParser.rkt and lex.rkt files.

To parse a program in our simple language, type the program code into a file, and call (parser "filename"). The parser will return the syntax tree in list format. For example, the syntax tree of the above code is:
((var x) (= x 10) (var y (+ (* 3 x) 5)) (while (!= (% y x) 3) (= y (+ y 1))) (if (> x y) (return x) (if (> (* x x) y) (return (* x x)) (if (> (* x (+ x x)) y) (return (* x (+ x x))) (return (- y 1))))))

Formally, a syntax tree is a list where each sublist corresponds to a statement. The different statements are:

variable declaration	(var variable) or (var variable value)
assignment	(= variable expression)
return	(return expression)
if statement	(if conditional then-statement optional-else-statement)
while statement	(while conditional body-statement)


Your Interpreter Program

You should write a function called interpret that takes a filename, calls parser with the filename, evaluates the syntax tree returned by parser, and returns the proper value. You are to maintain a state for the variables and return an error message if the user attempts to use a variable before it is declared. You can use the Scheme function (error ...) to return the error.

The State

Your state needs to store binding pairs, but the exact implementation is up to you. I recommend either a list of binding pairs (for example: ((x 5) (y 12) ...) ), or two lists, one with the variables and one with the values (for example: ((x y ...) (5 12 ...))). The first option will be simpler to program, but the second will be more easily adapted for an object-oriented language at the end of the course. The exact way you decide to implement looking up a binding, creating a new binding, or updating an existing binding is up to you. It is not essential that you be efficient here, just do something that works. With such a simple language, an efficient state is unneeded.

What you do have to do is use abstraction to separate your state from the rest of your interpreter. As we increase the number of language features we have in future parts of the project, we will need to change how the state is implemented. If you correctly use abstraction, you will be able to redesign the state without changing the implementation of your interpreter. In this case, that means that the interpreter does not know about the structure of the state. Instead, you have generic functions that the interpreter can call to manipulate the state.

Returning a Value

Your interpreter needs to return the proper value.  How you achieve this is up to you, and we will later learn the proper way to handle the return.  A simple solution that is sufficient for this project is to have a special variable called return in the state that you assign to the return value.  When you are done interpreting the program your code can then lookup return in the state, get, and return that value.

