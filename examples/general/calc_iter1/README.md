## Demo calculator (iteration 1)

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
