## Demo calculator (iteration 2)
Compared to the first iteration, this calculator adds:
- support for the exponentiation operator '**'
- support the the unary '-' operator (sign change).
It also prints out:
- The Concrete Syntax Tree (CST), a complete but verbose parse tree representation
- The Abstract Syntax Tree (AST), a customized parse tree representation that is more 
convenient for further processing (here calculation.).

### Source files
This sample project consists of the following files:  
- **calc_ast_builder.rb** containing the class `CalcASTBuilder` that creates
  the abstract syntax trees (AST) representation for a given parse result.  

- **calc_ast_nodes.rb** containing the node classes for implementing the AST.
The nodes have a 'interpret' method that computes of the numeric value of the
node.

- **calc_demo.rb** a demo command-line program.  
  It parses the expression in the command-line and outputs the numeric result
  For more details, run the command-line: `calc_demo.rb`

- **calc_grammar.rb** implementing the class `CalcGrammar`.  
  The grammar is a list of (production) rules that specifies the syntax of math 
  expression.   A little examination of the grammar will reveal interesting 
  grammar features such as:  
    * Recursive rules (e.g. terminal in left-side of rule also appears in right-hand side)

- **calc_lexer.rb** implementing  the class `CalcLexer`.  
  The purpose of the lexer is to break the math expression into a sequence of tokens.  

- **calc_parser.rb** implementing a `CalcParser` class.  
  The parser processes the tokens stream from the lexer and delivers its results

- **sample_result.txt** a sample text containing the output of calculator for the expression: 
2 * 3 + (1 + 3 ** 2). It illustrates the huge difference in size and nesting between the CST
(Concrete Syntax Tree) and the AST (Abstract Syntax Tree) representations. The generation of CSTs
comes out-of-the-box with **Rley**. Creating ASTs requires customization. Here, the class for the 
AST nodes of the AST are defined in the **calc_ast_nodes.rb** and the methods for assembling the
AST from the grammar rules are implemented in the `CalcASTBuilder` class.
