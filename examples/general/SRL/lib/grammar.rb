# Grammar for SRL (Simple Regex Language)
require 'rley' # Load the gem
module SRL
  ########################################
  # Work in progress.
  # This is a very partial grammar of SRL.
  # It will be expanded with the coming versions of Rley
  builder = Rley::Syntax::GrammarBuilder.new do
    add_terminals('DIGIT', 'INTEGER')
    add_terminals('EXACTLY', 'TIMES', 'ONCE', 'TWICE')
    add_terminals('BETWEEN', 'AND', 'OPTIONAL', 'OR')
    add_terminals('MORE', 'NEVER', 'AT', 'LEAST')

    # For the moment one focuses on quantifier syntax only...
    rule 'srl' => 'quantifier'
    rule 'quantifier' => 'ONCE'
    rule 'quantifier' => 'TWICE'
    rule 'quantifier' => %w[EXACTLY count TIMES]
    rule 'quantifier' => %w[BETWEEN count AND count times_suffix]
    rule 'quantifier' => 'OPTIONAL'
    rule 'quantifier' => %w[ONCE OR MORE]
    rule 'quantifier' => %w[NEVER OR MORE]
    rule 'quantifier' => %w[AT LEAST count TIMES]
    rule 'count' => 'DIGIT'
    rule 'count' => 'INTEGER'
    rule 'times_suffix' => 'TIMES'
    rule 'times_suffix' => []
  end

  # And now build the grammar and make it accessible via a global constant
  Grammar = builder.grammar
end # module