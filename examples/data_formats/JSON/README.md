## Demo JSON parser

### Source files
This sample project consists of the following files:  

- **JSON_demo.rb** a demo command-line program using the classes below.  
  It parses the JSON file specified in the command-line and converts the JSON
  into Labelled Bracket Notation (LBN).
  LBN output can be then used with tools/libraries that build tree diagrams.

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
