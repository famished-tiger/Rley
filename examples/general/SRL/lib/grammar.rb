# Grammar for SRL (Simple Regex Language)
require 'rley' # Load the gem
module SRL
  ########################################
  # Work in progress.
  # This is a very partial grammar of SRL.
  # It will be expanded with the coming versions of Rley
  builder = Rley::Syntax::GrammarBuilder.new do
    add_terminals('DIGIT_LIT', 'INTEGER', 'LETTER_LIT')
    add_terminals('UPPERCASE', 'LETTER', 'FROM', 'TO')
    add_terminals('DIGIT', 'NUMBER')
    add_terminals('EXACTLY', 'TIMES', 'ONCE', 'TWICE')
    add_terminals('BETWEEN', 'AND', 'OPTIONAL', 'OR')
    add_terminals('MORE', 'NEVER', 'AT', 'LEAST')

    # For the moment one focuses on quantifier syntax only...
    rule 'srl' => 'term'
    rule 'term' => 'atom'
    rule 'term' => %w[atom quantifier]
    rule 'atom' => 'letter_range'
    rule 'atom' => 'digit_range'
    rule 'letter_range' => %w[LETTER FROM LETTER_LIT TO LETTER_LIT]
    rule 'letter_range' => %w[UPPERCASE LETTER FROM LETTER_LIT TO LETTER_LIT]
    rule 'letter_range' => 'LETTER'
    rule 'letter_range' => %w[UPPERCASE LETTER]
    rule 'digit_range' => %w[digit_or_number FROM DIGIT_LIT TO DIGIT_LIT]
    rule 'digit_range' => 'digit_or_number'    
    rule 'quantifier' => 'ONCE'
    rule 'quantifier' => 'TWICE'
    rule 'quantifier' => %w[EXACTLY count TIMES]
    rule 'quantifier' => %w[BETWEEN count AND count times_suffix]
    rule 'quantifier' => 'OPTIONAL'
    rule 'quantifier' => %w[ONCE OR MORE]
    rule 'quantifier' => %w[NEVER OR MORE]
    rule 'quantifier' => %w[AT LEAST count TIMES]
    rule 'digit_or_number' => 'DIGIT'
    rule 'digit_or_number' => 'NUMBER'
    rule 'count' => 'DIGIT_LIT'
    rule 'count' => 'INTEGER'
    rule 'times_suffix' => 'TIMES'
    rule 'times_suffix' => []
  end

  # And now build the grammar and make it accessible via a global constant
  Grammar = builder.grammar
end # module