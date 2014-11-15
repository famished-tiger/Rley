# Purpose: to demonstrate how to build a very simple grammar
require 'rley'  # Load the gem

# A very simple language
# It recognizes/generates strings like 'b', 'abc', 'aabcc', 'aaabccc',...
# (based on example in N. Wirth's book "Compiler Construction", p. 6)
# S ::= A.
# A ::= "a" A "c".
# A ::= "b".


# Let's create the grammar step-by-step with the grammar builder:
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('a', 'b', 'c')
builder.add_non_terminals('S', 'A')
builder.add_production('S' => 'A')
builder.add_production('A' => %w(a A c))
builder.add_production('A' => 'b')

# And now build the grammar...
grammar_abc = builder.grammar

# Prove that it is a grammar
puts grammar_abc.class.name

# End of file

