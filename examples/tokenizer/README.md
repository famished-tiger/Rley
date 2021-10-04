Integrating a scanner generated with `oedipus_lex` gem with a Rley parser.
===

This folder contains a demo tokenizer for the `Lox` programming language.  
While tokenizers from other examples were handwritten, this one was generated with a tool.

The resulting tokenizer consists of two classes:
- The generated `LoxxyRawScanner` class (file: `loxxy_raw_scanner.rex.rb`).
- The handwritten `LoxxyTokenizer` class. Its purpose is explained later (file: `loxxy_tokenizer.rb`).

## How was the scanner class generated?

The `LoxxyRawScanner` class was generated from the specification file `loxxy_raw_scanner.rex`.  
This file has a format that can be read by the `oedipus lex`gem (the 'scanner generator').
The scanner generator then generates a Ruby class that implements a scanner.

The generation process is controled with a `Rakefile`.
Assuming that the gem is already installed, launch the following command line in this folder:
```ruby
rake tokenizer
```

Rake script should display the following message:
```ruby
Generating loxxy_raw_scanner.rex.rb from loxxy_raw_scanner.rex
```

## How to install `oedipus_lex`?
Use the standard installation step:
```ruby
gem install oedipus_lex
```

## Why the `oedipus_lex` scanner generator?
This gem was created as a companion to the `Racc` parser (part of Ruby's standard library).  
But the code it produces has no dependency towards a specific parser, 
so that it can used for building scanners for Rley parsers.

## What is the purpose of the`LoxxyTokenizer` class?
If the scanner can be generated, why do we need to handcode another class?
There were two reasons:
- First, `rex` files use particular syntax a domain-specific language (DSL). So I tend to minimize its use.
  Without the flexbility of Ruby, handling keywords directly in the `rex` can become cumbersone.
- Second, the `LoxxyTokenizer` class acts as an Adapter between the parser-neutral generated scanner and the expectations of a Rley parser.
  For instance, Rley expects the tokenizer to deliver a sequence of `Rley::Lexical::Token` instances.
  In addition, that class performs some convertion methods that are better implemented directly in Ruby. 