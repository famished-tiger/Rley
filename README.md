Rley
===========
[Homepage](https://github.com/famished-tiger/Rley) 


[![Build Status](https://travis-ci.org/famished-tiger/Rley.svg?branch=master)](https://travis-ci.org/famished-tiger/Rley)
[![Coverage Status](https://img.shields.io/coveralls/famished-tiger/Rley.svg)](https://coveralls.io/r/famished-tiger/Rley?branch=master)
[![Gem Version](https://badge.fury.io/rb/rley.svg)](http://badge.fury.io/rb/rley)
[![Dependency Status](https://gemnasium.com/famished-tiger/Rley.svg)](https://gemnasium.com/famished-tiger/Rley)

### What is Rley? ###
__Rley__ is a Ruby implementation of a Earley parser.  
The objective is to build a parser convenient for lightweight NLP (Natural Language Processing) purposes.  

Yet another parser?  
Yes and no. Rley doesn't aim to replace other very good programming language parsers for Ruby.
The latter are faster because they use faster algorithms at the price of a loss of generality
in the grammar/language they support.  
The Earley's algorithm being more general is able to parse input without imposing restriction on the context-free grammar.  
Consult Wikipedia to learn more about Earley's parsing algorithm.  

This project is in "early" stage.  
####Roadmap:
- Add more validation tests and sample grammars
- Add AST generation (and semantic actions?)
- Add DSL for grammar specification
- Add grammar validations
- Add error reporting
- Add examples (including small NLP grammar)
- Add a command-line interface
- Provide documentation and examples


Copyright
---------
Copyright (c) 2014, Dimitri Geshef. 
__Rley__ is released under the MIT License see [LICENSE.txt](https://github.com/famished-tiger/Rley/blob/master/LICENSE.txt) for details.
