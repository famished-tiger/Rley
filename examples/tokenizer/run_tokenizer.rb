# frozen_string_literal: true

require 'yaml'
require_relative 'loxxy_tokenizer'

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

loxxy_tokenizer = LoxxyTokenizer.new
loxxy_tokenizer.start_with(lox_source)
tokens = loxxy_tokenizer.tokens
File::open('tokens.yaml', 'w') { |f| YAML.dump(tokens, f) }
puts 'Done: tokenizer results saved in YAML.'
