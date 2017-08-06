## Demo JSON parser and JSON utilities.
This small project shows how to:
- Define a JSON grammar
- Build a simple parser (and lexer)
- Output the resulting parse tree in different representations
- Create a JSON minifier in less than 50 lines that comptacts JSON text.

To try the command-line, do:  
ruby json_demo.rb --help


### Source files
This sample project consists of the following files:  
- **cli_opt.rb** containing the utility class CLIOptions that retrieves the
  command-line options.

- **json_demo.rb** a demo command-line program.  
  It parses the JSON file specified in the command-line and outputs the parse tree
  into different formats. For more details, run the command-line: `json_demo --help`

- **json_grammar.rb** implementing the class `JSONGrammar`.  
  The grammar is a list of (production) rules that specifies the syntax of JSON data.  
  A little examination of the grammar will reveal interesting grammar features such as:  
    * Recursive rules (e.g. terminal in left-side of rule also appears in right-hand side)

- **json_lexer.rb** implementing  the class `JSONLexer`.  
  The purpose of the lexer is to break the JSON source text into a sequence of tokens.  

- **json_minifier.rb** implementing  the class `JSONMinifier`.  
  The JSON minifier strips all unnecessary whitespaces in the JSON input. It emits the resulting "minified" JSON
  that has typically a size reduced by half.
  
- **json_parser.rb** implementing a `JSONParser` class.  
  The parser processes the tokens stream from the lexer and delivers its results  


- sample0x.json files of various degree of complexity.  

- sample0x.svg files that are syntax tree diagrams obtained by feeding [RSyntaxTree](http://yohasebe.com/rsyntaxtree/) with the output of JSON_demo.rb. Remark: the website works best with not too complex parse trees.
