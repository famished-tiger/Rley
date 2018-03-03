## Directory contents
This directory contains a number sample projects and short demos.  

- [calc_iter1](#demo-calculators)  
- [calc_iter2](#demo-calculators)  
- [SPPF](#Shared-Packed-Parse-Forest)  
- [SRL](#Simple-Regex-Language)  
- [left.rb](#recursive-rules)  
- [right.rb](#recursive-rules)


### Demo calculators
Two command-line tools that parse basic math expressions
and calculate their numeric values.

There are two variants of the calculator:
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
error reporting), great care was taken about their modularity.

### Shared Packed Parse Forest
This directory will contain code showing how to use and manipulate SPPFs.

### Recursive rules
The files `left.rb` and `right.rb` show how to define left- and right-recursive rules respectively. These examples were used to benchmark the parsing. Although `Rley` can handle right-recursive rules, one should avoid deeply-nested right-recursive rule calls. The reason is that in these situations the number of possible parse states increases rapidly and affects severely the parsing speed. There are optimization techniques addressing the issue e.g. [Leo's optimization](http://www.sciencedirect.com/science/article/pii/030439759190180A) that may eventually be implemented in Rley provided that they don't put limits on the NLP capabilities. Here is another link about [Leo's optimization](http://loup-vaillant.fr/tutorials/earley-parsing/right-recursion)
