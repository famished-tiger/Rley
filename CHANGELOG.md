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