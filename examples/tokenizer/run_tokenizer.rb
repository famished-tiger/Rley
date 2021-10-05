# frozen_string_literal: true

# Demo script that illustrates how to scan a Lox code snippet
# into a stream of Rley token objects & serialize them into a YAML file.

require 'yaml'
require_relative 'loxxy_tokenizer'

# Here is a Lox code snippet
lox_source = <<LOX_END
class Base {
  foo() {
    print "Base.foo()";
  }
}

class Derived < Base {
  foo() {
    print "Derived.foo()";
    super.foo();
  }
}

Derived().foo();
// expect: Derived.foo()
// expect: Base.foo()
LOX_END


loxxy_tokenizer = LoxxyTokenizer.new(lox_source)
tokens = loxxy_tokenizer.tokens
File::open('tokens.yaml', 'w') { |f| YAML.dump(tokens, f) }
puts 'Done: tokenizer results saved in YAML.'
