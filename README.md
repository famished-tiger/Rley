[Rley](https://github.com/famished-tiger/Rley)

[![Linux Build Status](https://img.shields.io/travis/famished-tiger/Rley/master.svg?label=Linux%20build)](https://travis-ci.org/famished-tiger/Rley)
[![Build status](https://ci.appveyor.com/api/projects/status/l5adgcbfo128rvo9?svg=true)](https://ci.appveyor.com/project/famished-tiger/rley)
[![Coverage Status](https://img.shields.io/coveralls/famished-tiger/Rley.svg)](https://coveralls.io/r/famished-tiger/Rley?branch=master)
[![Gem Version](https://badge.fury.io/rb/rley.svg)](http://badge.fury.io/rb/rley)
[![Dependency Status](https://gemnasium.com/famished-tiger/Rley.svg)](https://gemnasium.com/famished-tiger/Rley)
[![Inline docs](http://inch-ci.org/github/famished-tiger/Rley.svg?branch=master)](http://inch-ci.org/github/famished-tiger/Rley)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](https://github.com/famished-tiger/Rley/blob/master/LICENSE.txt)

A Ruby library for constructing general parsers for _any_ context-free language.  

====


What is Rley?
-------------
__Rley__ uses the [Earley](http://en.wikipedia.org/wiki/Earley_parser)
algorithm which is a general parsing algorithm that can handle any context-free
grammar. Earley parsers can literally swallow anything that can be described
by a context-free grammar. That's why Earley parsers find their place in so
many __NLP__ (_Natural Language Processing_) libraries/toolkits.  

In addition, __Rley__ goes beyond most Earley parser implementations by providing
support for ambiguous parses. Indeed, it delivers the results of a parse as a
_Shared Packed Parse Forest_ (SPPF). A SPPF is a data structure that allows to
encode efficiently all the possible parse trees that result from an ambiguous
grammar.  

As another distinctive mark, __Rley__ is also the first Ruby implementation of a
parsing library based on the new _Grammar Flow Graph_ approach [References on GFG](#references-on-gfg).

### What it can do?
Maybe parsing algorithms and internal implementation details are of lesser
interest to you and the good question to ask is "what Rley can really do?".  

In a nutshell:  
* Rley can parse context-free languages that other well-known libraries cannot
handle  
* Built-in support for ambiguous grammars that typically occur in NLP

In short, the foundations of Rley are strong enough to be useful in a large
application range such as:  
* computer languages,  
* artificial intelligence and  
* Natural Language Processing.

### Features
* Simple API for context-free grammar definition,
* Allows ambiguous grammars,
* Generates shared packed parse forests,
* Accepts left-recursive rules/productions,
* Provides syntax error detection and reporting.


### Compatibility
Rley supports the following Ruby implementations:  
- MRI 2.0  
- MRI 2.1  
- MRI 2.2  
- MRI 2.3  
- JRuby 9.0+  

---

Getting Started
---------------

### Installation
Installing the latest stable version is simple:

    $ gem install rley


## A whirlwind tour of Rley
The purpose of this section is show how to create a parser for a minimalistic
English language subset.
The tour is organized as follows:  
1. [Defining the language grammar](#defining-the-language-grammar)  
2. [Creating a lexicon](#creating-a-lexicon)  
3. [Creating a tokenizer](#creating-a-tokenizer)  
4. [Building the parser](#building-the-parser)  
5. [Parsing some input](#parsing-some-input)  
6. [Generating the parse forest](#generating-the-parse-forest)

The complete source code of the example used in this tour can be found in the
[examples](https://github.com/famished-tiger/Rley/tree/master/examples/NLP/mini_en_demo.rb)
directory

### Defining the language grammar
The subset of English grammar is based on an example from the NLTK book.

```ruby  
    require 'rley'  # Load Rley library

    # Instantiate a builder object that will build the grammar for us
    builder = Rley::Syntax::GrammarBuilder.new do
      # Terminal symbols (= word categories in lexicon)
      add_terminals('Noun', 'Proper-Noun', 'Verb')
      add_terminals('Determiner', 'Preposition')

      # Here we define the productions (= grammar rules)
      rule 'S' => %w[NP VP]
      rule 'NP' => 'Proper-Noun'
      rule 'NP' => %w[Determiner Noun]
      rule 'NP' => %w[Determiner Noun PP]
      rule 'VP' => %w[Verb NP]
      rule 'VP' => %w[Verb NP PP]
      rule 'PP' => %w[Preposition NP]
    end
    # And now, let's build the grammar...
    grammar = builder.grammar
```  

## Creating a lexicon

```ruby
    # To simplify things, lexicon is implemented as a Hash with pairs of the form:
    # word => terminal symbol name
    Lexicon = {
      'man' => 'Noun',
      'dog' => 'Noun',
      'cat' => 'Noun',
      'telescope' => 'Noun',
      'park' => 'Noun',  
      'saw' => 'Verb',
      'ate' => 'Verb',
      'walked' => 'Verb',
      'John' => 'Proper-Noun',
      'Mary' => 'Proper-Noun',
      'Bob' => 'Proper-Noun',
      'a' => 'Determiner',
      'an' => 'Determiner',
      'the' => 'Determiner',
      'my' => 'Determiner',
      'in' => 'Preposition',
      'on' => 'Preposition',
      'by' => 'Preposition',
      'with' => 'Preposition'
    }
```  


## Creating a tokenizer
```ruby
    # A tokenizer reads the input string and converts it into a sequence of tokens
    # Highly simplified tokenizer implementation.
    def tokenizer(aText, aGrammar)
      tokens = aText.scan(/\S+/).map do |word|
        term_name = Lexicon[word]
        if term_name.nil?
          raise StandardError, "Word '#{word}' not found in lexicon"
        end
        terminal = aGrammar.name2symbol[term_name]
        Rley::Tokens::Token.new(word, terminal)
      end

      return tokens
    end
```

More ambitious NLP applications will surely rely on a Part-of-Speech tagger instead of
creating a lexicon and tokenizer from scratch. Here are a few Ruby Part-of-Speech gems:  
* [engtagger](https://rubygems.org/gems/engtagger)
* [rbtagger](https://rubygems.org/gems/rbtagger)



## Building the parser
```ruby
  # Easy with Rley...
  parser = Rley::Parser::GFGEarleyParser.new(grammar)
```


## Parsing some input
```ruby
    input_to_parse = 'John saw Mary with a telescope'
    # Convert input text into a sequence of token objects...
    tokens = tokenizer(input_to_parse, grammar)
    result = parser.parse(tokens)

    puts "Parsing successful? #{result.success?}" # => Parsing successful? true
```

## Generating the parse forest
```ruby
    pforest = result.parse_forest
```

## Error reporting
__Rley__ is a non-violent parser, that is, it won't throw an exception when it
detects a syntax error. Instead, the parse result will be marked as
non-successful. The parse error can then be identified by calling the
`GFGParsing#failure_reason` method. This method returns an error reason object
which can help to produce an error message.  

Consider the example from the [Parsing some input](#parsing-some-input) section
above and, as an error, we delete the verb `saw` in the sentence to parse.  

```ruby
    # Verb has been removed from the sentence on next line
    input_to_parse = 'John Mary with a telescope'
    # Convert input text into a sequence of token objects...
    tokens = tokenizer(input_to_parse, grammar)
    result = parser.parse(tokens)

    puts "Parsing successful? #{result.success?}" # => Parsing successful? false
    exit(1)
```

As expected, the parse is now failing.  
To get an error message, one just need to retrieve the error reason and
ask it to generate a message.  
```ruby
    # Show error message if parse fails...
    puts result.failure_reason.message unless result.success?
```

Re-running the example with the error, result in the error message:
```
  Syntax error at or near token 2 >>>Mary<<<
  Expected one 'Verb', found a 'Proper-Noun' instead.
```

The standard __Rley__ message not only inform about the location of
the mistake, it also provides some hint by disclosing its expectations.

Let's experiment again with the original sentence but without the word
`telescope`.

```ruby
    # Last word has been removed from the sentence on next line
    input_to_parse = 'John saw Mary with a '
    # Convert input text into a sequence of token objects...
    tokens = tokenizer(input_to_parse, grammar)
    result = parser.parse(tokens)

    puts "Parsing successful? #{result.success?}" # => Parsing successful? false
    unless result.success?
      puts result.failure_reason.message
      exit(1)
    end
```

This time, the following output is displayed:
```
  Parsing successful? false
  Premature end of input after 'a' at position 5
  Expected one 'Noun'.
```
Again, the resulting error message is user-friendly.  
Remark: currently, Rley reports an error position as the index of the  
input token with which the error was detected.


## Examples

The project source directory contains several example scripts that demonstrate
how grammars are to be constructed and used.


## Other similar Ruby projects
__Rley__ isn't the sole implementation of the Earley parser algorithm in Ruby.  
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
- [linguist project](https://github.com/davidkellis/linguist) -- Advertised as a library for parsing context-free languages.  
  It is a recognizer not a parser. In other words it can only tell whether a given input
  conforms to the grammar rules or not. As such it cannot build parse trees.  
  The code doesn't seem to be maintained: latest commit dates from Oct. 2011.


##  Thanks to:
* Professor Keshav Pingali, one of the creators of the Grammar Flow Graph parsing approach for his encouraging e-mail exchanges.

## References on GFG
Since the __G__rammar __F__low __G__raph parsing approach is quite new, it has not yet taken a place in
standard parser textbooks. Here are a few references (and links) of papers on GFG:    
- K. Pingali, G. Bilardi. [Parsing with Pictures](http://apps.cs.utexas.edu/tech_reports/reports/tr/TR-2102.pdf)
- K. Pingali, G. Bilardi. [A Graphical Model for Context-Free Grammar Parsing.](https://link.springer.com/chapter/10.1007/978-3-662-46663-6_1)
  In : International Conference on Compiler Construction. Springer Berlin Heidelberg, 2015. p. 3-27.  
- M. Fulbright. [An Evaluation of Two Approaches to Parsing](http://apps.cs.utexas.edu/tech_reports/reports/tr/TR-2199.pdf)  


Copyright
---------
Copyright (c) 2014-2017, Dimitri Geshef.  
__Rley__ is released under the MIT License see [LICENSE.txt](https://github.com/famished-tiger/Rley/blob/master/LICENSE.txt) for details.
