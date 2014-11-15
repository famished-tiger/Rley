# Purpose: to demonstrate how to build a very simple grammar
require 'rley'  # Load the gem

# Sample grammar for a very limited English language
# based on the language L0 from Jurafsky & Martin

# Let's create the grammar step-by-step with the grammar builder:
builder = Rley::Syntax::GrammarBuilder.new

# Enumerate the POS Part-Of-Speech...
builder.add_terminals('Noun', 'Verb', 'Adjective')
builder.add_terminals('Pronoun', 'Proper-Noun', 'Determiner')
builder.add_terminals('Preposition', 'Conjunction')

# Enumerate the non-terminal symbols...
builder.add_non_terminals('S', 'NP', 'Nominal', 'VP', 'PP')

# Now the production rules...
builder.add_production('S'=> ['NP', 'VP']) # e.g. I + want a morning flight
builder.add_production('NP' => 'Pronoun')  # e.g. I
builder.add_production('NP' => 'Proper-Noun') # e.g. Los Angeles
builder.add_production('NP' => ['Det', 'Nominal'])  # e.g. a + flight
builder.add_production('Nominal' => %w(Nominal Noun)) # morning + flight
builder.add_production('Nominal' => 'Noun') # e.g. flights
builder.add_production('VP' => 'Verb')      # e.g. do
builder.add_production('VP' => ['Verb', 'NP'])  # e.g. want + a flight
builder.add_production('VP' => ['Verb', 'NP', 'PP'])
builder.add_production('VP' => ['Verb', 'PP']) # leaving + on Thursday
builder.add_production('PP' => ['Preposition', 'NP']) # from + Los Angeles

# And now we 're ready to build the grammar...
grammar_L0 = builder.grammar

# Prove that it is a grammar
puts grammar_L0.class.name