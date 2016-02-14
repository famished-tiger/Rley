Rley
===========
[Homepage](https://github.com/famished-tiger/Rley) 


[![Build Status](https://travis-ci.org/famished-tiger/Rley.svg?branch=master)](https://travis-ci.org/famished-tiger/Rley)
[![Coverage Status](https://img.shields.io/coveralls/famished-tiger/Rley.svg)](https://coveralls.io/r/famished-tiger/Rley?branch=master)
[![Gem Version](https://badge.fury.io/rb/rley.svg)](http://badge.fury.io/rb/rley)
[![Dependency Status](https://gemnasium.com/famished-tiger/Rley.svg)](https://gemnasium.com/famished-tiger/Rley)
[![Inline docs](http://inch-ci.org/github/famished-tiger/Rley.svg?branch=master)](http://inch-ci.org/github/famished-tiger/Rley)
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
- Rewrite the parser using the GFG (Grammar Flow Graph) approach
- Replace parse trees by shared packed parse forests
- Document the parser API
- Add more validation tests and sample grammars
- Add a command-line interface
- Provide documentation and examples


### Other similar Ruby projects ###
__Rley__ isn't the sole Ruby implementation of the Earley parser algorithm.  
Here are a few other ones:  
- [Kanocc gem](https://rubygems.org/gems/kanocc) -- Advertised as a Ruby based parsing and translation framework.  
  Although the gem dates from 2009, the author still maintains its in a public repository in [Github](https://github.com/surlykke/Kanocc)  
  The grammar symbols (tokens and non-terminals) must be represented as (sub)classes.
  Grammar rules are methods of the non-terminal classes. A rule can have a block code argument
  that specifies the semantic action when that rule is applied.  
- [lc1 project](https://github.com/kp0v/lc1) -- Advertised as a combination of Earley and Viterbi algorithms for [Probabilistic] Context Free Grammars   
  Aimed in parsing brazilian portuguese.  
  [earley project](https://github.com/joshingly/earley) -- An Earley parser (grammar rules are specified in JSON format).  
  The code doesn't seem to be maintained: latest commit dates from Nov. 2011.  
- [linguist project](https://github.com/davidkellis/linguist) -- Advertised as library for parsing context-free languages.  
  It is a recognizer not a parser. In other words it can only tell whether a given input 
  conforms to the grammar rules or not. As such it cannot build parse trees.  
  The code doesn't seem to be maintained: latest commit dates from Oct. 2011.

Copyright
---------
Copyright (c) 2014-2016, Dimitri Geshef. 
__Rley__ is released under the MIT License see [LICENSE.txt](https://github.com/famished-tiger/Rley/blob/master/LICENSE.txt) for details.
