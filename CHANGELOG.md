### 0.1.06 / 2014-12-13
* [NEW] New parse tree formatting class `JSON` for parse tree rendition in JSON.
* [FIX] Method `Parsing#parse_tree` now add link to Token object for last TerminalNode in tree.

### 0.1.05 / 2014-12-10
* [NEW] New parse tree formatting classes `BaseFormatter` and `Debug`
* [CHANGE] Method `Parsing#parse_tree` now add links to Token objects in TerminalNodes.

### 0.1.04 / 2014-12-08
* [CHANGE] File `parse_tree_visitor_spec.rb`. Added step-by-step test of a parse tree visit.


### 0.1.03 / 2014-12-08
* [NEW] `ParseTreeVisitor` class. A class that walks through a parse tree.
* [NEW] Method `accept` added to `ParseTree`, `TerminalNode`, `NonTerminalNode` classes.

### 0.1.02 / 2014-12-06
* [CHANGE] Upgraded code & spec files to reach 100% code coverage again.


### 0.1.01 / 2014-12-06
* [CHANGE] Restaured test coverage to above 99%

### 0.1.00 / 2014-12-05
* [CHANGE] Bumped version number: it is the first version able to generate a parse tree.
* [NEW] `Grammar#name2symbol` attribute and accessor. Retrieve a grammar symbol from its name.
* [NEW] Methods `DottedItem#prev_symbol`, `DottedItem#prev_position` to find symbol on left of dot.
* [NEW] Method `ParseState#precedes?`, predicate to check whether self is a predecessor of given parse state.
* [NEW] Method `Parsing#parse_tree` returns a ParseTree object that represents the result of a parse.


### 0.0.18 / 2014-11-23
* [CHANGE] `EarleyParser#parse`: Optimization prevent repeated prediction of same non-terminal for same state set.
* [CHANGE] File `earley_parser_spec.rb`: Added new test for nullable grammar.
* [CHANGE] Style refactoring in classes `EarleyParser`, `StateSet`, `Grammar`, `NonTerminal`

### 0.0.17 / 2014-11-23
* [CHANGE] File `earley_parser_spec.rb`: Added step-by-step test of ambiguous grammar parsing.

### 0.0.16 / 2014-11-23
* [NEW]  Method `DottedItem#to_s` Returns a text representation of an instance.
* [NEW]  Method `ParseState#to_s`
* [NEW]  Method `GrmSymbol#to_s`
* [NEW]  Method `VerbatimSymbol#to_s`
* [CHANGE] File `earley_parser_spec.rb`: Parse tests refactored.


### 0.0.15 / 2014-11-20
* [FIX]  `EarleyParser` class source code was out-of-sync.

### 0.0.14 / 2014-11-20
* [NEW]  `EarleyParser` now supports grammar with empty productions (i.e. nullable nonterminals).
* [CHANGE]  (private) method `EarleyParser#prediction` updated with Ayock-Horspool improvement.
* [CHANGE]  Moved class `DottedItem` under the `Parser` module.

### 0.0.13 / 2014-11-19
* [NEW]  (private) method `Grammar#compute_nullable` added.
* [CHANGE] `Grammar#initialize` constructor calls the method `Grammar#compute_nullable`


### 0.0.12 / 2014-11-17
* [CHANGE]  Classes `Terminal` and `NonTerminal` added new method nullable?
* [CHANGE] File `earley_parser_spec.rb`: Added spec with ambiguous grammar.


### 0.0.11 / 2014-11-16
* [CHANGE]  Usage of `GrammarBuilder`simplified: the call to method `GrammarBuilder#add_non_terminal` isn't necessary. Method is removed 
* [CHANGE] Updated the `examples` folder accordingly.

### 0.0.10 / 2014-11-15
* [NEW]  New folder `examples` added with two examples of grammar creation 

### 0.0.09 / 2014-11-15
* [NEW]  New class `GrammarBuilder` added and tested, its purpose is 
to simplify the construction of grammars.

### 0.0.08 / 2014-11-14
* [CHANGE]  `EarleyParser#parse` method: Initial API documentation.
* [INFO] This version was committed to force Travis CI to execute a complete build 
failed because Travis couldn't connect to GitHub)

### 0.0.07 / 2014-11-14
* [CHANGE]  spec file of `EarleyParser` class: Test added. Parser works with simple expression grammar.

### 0.0.06 / 2014-11-13
* [CHANGE] File `README.md`: Added roadmap section.
* [FIX] `EarleyParser#parse`: prevent call to `scanning` method after last token encountered.

### 0.0.05 / 2014-11-13
* [CHANGE] Code re-styling to please Rubocop 0.27.0 (less than 10 offenses).

### 0.0.04 / 2014-11-12
* [CHANGE] Class `DottedItem` moved to `Rley` module.

### 0.0.03 / 2014-11-12
* [CHANGE] File `README.md`: Added gem version badge.


### 0.0.02 / 2014-11-12
* [CHANGE] File `README.md`: Added Travis CI badge.


### 0.0.01 / 2014-11-12
* [CHANGE] Rley is "gemmified"!


### 0.0.00 / 2014-11-07
* [FEATURE] Initial public working version