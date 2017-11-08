## Demo calculator
The purpose is show how a basic command-line tool can parse a math expression
and calculates its numeric value.

There are two variants of the calcultator:
- **Iteration 1**. A simple calculator program that handles expressions with the  
  4 basic arithmetic operators: + - * and /
- **Iteration 2**. A significantly more elaborated calculator that adds:  
 support for the exponentiation operator and the unary minus (sign change),  
 PI and E constants,  
 trigonometric functions, inverse trigonometric functions,  
 square root, exponential and natural logarithm functions.

As a bonus, the iteration 2 calculator prints out:
- The Concrete Syntax Tree (**CST**), a complete but verbose parse tree representation
- The Abstract Syntax Tree (**AST**), a customized parse tree representation that is simpler
for further processing (i.e. calculation, execution,...).

Although these calculators are demo apps (read: they lack robust error handling and user friendly
error reporting), great care about their modularity.
