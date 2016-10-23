### 0.3.00 / 2016-10-23
* [CHANGE] Many new classes. The gem bundles a second parser that copes with ambiguous grammars. 


### 0.2.15 / 2016-02-14
* [CHANGE] A lot of internal changes. This is the last version before a Grammar Flow Graph-based parsing implementation.

### 0.2.14 / 2015-11-25
* [FIX] Method `StateSet#ambiguities` overlooked some ambiguities in parse sets.

### 0.2.13 / 2015-11-25
* [NEW] method `Parsing#ambiguous?` returns true if more than one successful parse tree can be retried from parse results.
* [CHANGED] method `Parsing#success?`. New implementation that relies on start symbol derivation.
* [NEW] New method `Chart#start_symbol` added. Returns the start symbol of the grammar.
* [NEW] New method `StateSet#ambiguities` added. Returns the parse sets that are ambiguous (= distinct derivation for same input tokens).
* [FIX] In special cases the parsing didn't work correctly when there more than one 
    production rule for the start symbol of a grammar.

### 0.2.12 / 2015-11-20
* [FIX] In special cases the parsing didn't work correctly when there more than one 
    production rule for the start symbol of a grammar.

### 0.2.11 / 2015-09-05
* [CHANGE] Code re-formatted to please Rubocop 0.34.0
* [CHANGE] File `.travis.yml`: added new Rubies: MRI 2.2.0 and JRuby 9.0.
* [CHANGE] File `rley.gemspec`: Upgraded gem versions in development dependencies
* [CHANGE] File `Gemfile`: Upgraded gem versions in development dependencies

### 0.2.10 / 2015-06-16
* [CHANGE] Code re-formatted to please Rubocop 0.32.0
* [FIX] File `.rubocop.yml`: disable some cop settings that were too loud.

### 0.2.08 / 2015-04-28
* [NEW] Added folder with JSON demo parser under `examples\parsers\demo-JSON`.

### 0.2.07 / 2015-04-22
* [NEW] Rake file added in `examples` folder. It allows to run all the examples at once.

### 0.2.06 / 2015-03-21
* [FIX] Method `EarleyParser#handle_error` portability issue between Ruby versions.


### 0.2.05 / 2015-03-19
* [NEW] Class `EarleyParser` implements a crude error detection mechanism. A syntax error causes an exception to be raised.
* [CHANGE] Examplar file `parsing_err_expr.rb`: demo error message.

### 0.2.04 / 2015-03-04
* [NEW] Class `ParseTracer` that helps to trace the parse steps (similar the trace format in NLTK).
* [CHANGE] Method `EarleyParser#parse` takes a trace level argument.


### 0.2.03 / 2015-02-06
* [FIX] File `.rubocop.yml`: removal of setting for obsolete EmptyLinesAroundBody cop.
* [CHANGE] Source code re-formatted to please Rubocop 0.29.
* [CHANGE] File `README.md` added licensing badge (MIT license)

### 0.2.02 / 2015-02-02
* [NEW] Examplar file `parsing_L1.rb`: demo using a (highly simplified) English grammar.
* [NEW] Examplar file `parsing_amb.rb`: demo using an ambiguous grammar.
* [FIX] Method `Parsing#parse_tree` now produces correct parse trees for all the examples.

### 0.2.01 / 2015-01-03
* [CHANGE] File `.rubocop.yml`: AbcMetric setting relaxed.
* [CHANGE] Fixed most style offenses reported by Rubocop.

### 0.2.00 / 2015-01-03  
Version number bump: major re-design of the parse tree generation.
* [NEW] Class `ParseTreeBuilder`: builder for creating parse tree.
* [NEW] Class `ParseStateTracker`: helper class used in parse tree generation.
* [NEW] Examplar file `parsing_L0.rb`: demo using a (highly simplified) English grammar.
* [CHANGE]  Class `ParseTree`: construction methods removed.
* [CHANGE]  Method `Parsing#parse_tree` completely rewritten.
* [FIX] Method `Parsing#parse_tree` now handles situations where there are multiple complete parse states for a non-terminal.

### 0.1.12 / 2014-12-22
* [FIX] Fixed `Parsing#parse_tree`: code couldn't cope with parse state set containing more 
  than one parse state that expected the same symbol.
* [NEW] Added one more parser example (for very basic arithmetic expression)

### 0.1.11 / 2014-12-16
* [FIX] Fixed all but one YARD (documentation) warnings. Most of them were due to mismatch
in method argument names between source code and documentation.  
* [CHANGE] File `README.md` added Gemnasium badge (for the gem dependency checks)

### 0.1.10 / 2014-12-14
* [CHANGE] Added more examples in `examples` folder (e.g. parsing then parse tree ).
* [CHANGE] File `rley.rb`: added more requires of the library to ease integration.

### 0.1.09 / 2014-12-14
* [CHANGE] Source code refactored to please Rubocop (0.28.0)
* [CHANGE] File `.rubucop.yml`  Disabled VariableNam style cop.

### 0.1.08 / 2014-12-13
* [CHANGE] File `README.md` added coveralls badge (for the test coverage)

### 0.1.07 / 2014-12-13
* [NEW] Added development dependency on 'coveralls' gem (for test coverage measurement)

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