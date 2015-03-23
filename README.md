Rley
===========
[Homepage](https://github.com/famished-tiger/Rley) 


[![Build Status](https://travis-ci.org/famished-tiger/Rley.svg?branch=master)](https://travis-ci.org/famished-tiger/Rley)
[![Coverage Status](https://img.shields.io/coveralls/famished-tiger/Rley.svg)](https://coveralls.io/r/famished-tiger/Rley?branch=master)
[![Gem Version](https://badge.fury.io/rb/rley.svg)](http://badge.fury.io/rb/rley)
[![Dependency Status](https://gemnasium.com/famished-tiger/Rley.svg)](https://gemnasium.com/famished-tiger/Rley)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](https://github.com/famished-tiger/Rley/blob/master/LICENSE.txt)

__Rley__ is a Ruby implementation of a parser using the [Earley](http://en.wikipedia.org/wiki/Earley_parser) algorithm.  
The project aims to build a parser convenient for lightweight NLP (Natural Language Processing) purposes.  

### Highlights ###
* Handles any context-free language,
* Accepts left-recursive rules/productions,
* Accepts ambiguous grammars,
* Parse tracing facility,
* Parse tree generation,
* Syntax error detection and reporting.


### Yet another parser? ###
Yes and no. Rley doesn't aim to replace other very good programming language parsers for Ruby.
The latter are faster because they use optimized algorithms at the price of a loss of generality
in the grammar/language they support.  
The Earley's algorithm being more general is able to parse input that conforms to any context-free grammar.

This project is in "earley" stage.  
####Roadmap:
- Document the parser API
- Add more validation tests and sample grammars
- Add AST generation (and semantic actions?)
- Add DSL for grammar specification
- Add grammar validations
- Add error reporting

- Add a command-line interface
- Provide documentation and examples



Copyright
---------
Copyright (c) 2014-2015, Dimitri Geshef. 
__Rley__ is released under the MIT License see [LICENSE.txt](https://github.com/famished-tiger/Rley/blob/master/LICENSE.txt) for details.
