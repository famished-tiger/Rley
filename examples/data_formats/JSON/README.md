## Demo JSON parser

### Source files
This sample project consists of the following files:  
- **cli_opt.rb** containing the utility class `CLIOptions` that retrieves the
  command-line options.

- **json_ast_builder.rb** containing the class `JSONASTBuilder` that creates
  the abstract syntax trees (AST) representation for a given parse result.  

- **json_ast_nodes.rb** containing the node classs for implementing the AST.
The nodes are augmented with methods that allow the re-use of some formatters
designed initially for CST (Concrete Syntax Tree). The nodes have a 'to_ruby'
method that enable a conversion of the input JSON text into Ruby representation.

- **JSON_demo.rb** a demo command-line program.  
  It parses the JSON file specified in the command-line and outputs the parse tree
  into different formats. For more details, run the command-line: `JSON_demo.rb --help`

- **JSON_grammar.rb** implementing the class `JSONGrammar`.  
  The grammar is a list of (production) rules that specifies the syntax of JSON data.  
  A little examination of the grammar will reveal interesting grammar features such as:  
    * Recursive rules (e.g. terminal in left-side of rule also appears in right-hand side)

- **JSON_lexer.rb** implementing  the class `JSONLexer`.  
  The purpose of the lexer is to break the JSON source text into a sequence of tokens.  

- **JSON_parser.rb** implementing a `JSONParser` class.  
  The parser processes the tokens stream from the lexer and delivers its results  


- sample0x.json files of various degree of complexity.  

- sample0x.svg files that are syntax tree diagrams obtained by feeding [RSyntaxTree](http://yohasebe.com/rsyntaxtree/) with the output of JSON_demo.rb. Remark: the website works best with not too complex parse trees.
