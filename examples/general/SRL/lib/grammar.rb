# Grammar for SRL (Simple Regex Language)
require 'rley' # Load the gem
module SRL
  ########################################
  # Work in progress.
  # This is a very partial grammar of SRL.
  # It will be expanded with the coming versions of Rley
  builder = Rley::Syntax::GrammarBuilder.new do
    add_terminals('LPAREN', 'RPAREN', 'COMMA')
    add_terminals('DIGIT_LIT', 'INTEGER', 'LETTER_LIT')
    add_terminals('LITERALLY', 'STRING_LIT')
    add_terminals('UPPERCASE', 'LETTER', 'FROM', 'TO')
    add_terminals('DIGIT', 'NUMBER', 'ANY', 'NO')
    add_terminals('CHARACTER', 'WHITESPACE', 'ANYTHING')
    add_terminals('TAB', 'BACKSLASH', 'NEW', 'LINE')
    add_terminals('OF', 'ONE')
    add_terminals('EXACTLY', 'TIMES', 'ONCE', 'TWICE')
    add_terminals('BETWEEN', 'AND', 'OPTIONAL', 'OR')
    add_terminals('MORE', 'NEVER', 'AT', 'LEAST')

    rule 'srl' => 'pattern'
    rule 'pattern' => %w[pattern COMMA quantifiable]
    rule 'pattern' => %w[pattern quantifiable]
    rule 'pattern' => 'quantifiable'
    rule 'quantifiable' => 'term'
    rule 'quantifiable' => %w[term quantifier]
    rule 'term' => 'atom'
    rule 'term' => 'alternation'
    rule 'term' => 'grouping'
    rule 'atom' => 'letter_range'
    rule 'atom' => 'digit_range'
    rule 'atom' => 'character_class'
    rule 'atom' => 'special_char'
    rule 'atom' => 'literal'
    rule 'letter_range' => %w[LETTER FROM LETTER_LIT TO LETTER_LIT]
    rule 'letter_range' => %w[UPPERCASE LETTER FROM LETTER_LIT TO LETTER_LIT]
    rule 'letter_range' => 'LETTER'
    rule 'letter_range' => %w[UPPERCASE LETTER]
    rule 'digit_range' => %w[digit_or_number FROM DIGIT_LIT TO DIGIT_LIT]
    rule 'digit_range' => 'digit_or_number'
    rule 'character_class' => %w[ANY CHARACTER]
    rule 'character_class' => %w[NO CHARACTER]
    rule 'character_class' => 'WHITESPACE'
    rule 'character_class' => %w[NO WHITESPACE]
    rule 'character_class' => 'ANYTHING'
    rule 'character_class' => %w[ONE OF STRING_LIT]
    rule 'special_char' => 'TAB'
    rule 'special_char' => 'BACKSLASH'
    rule 'special_char' => %w[NEW LINE]
    rule 'literal' => %w[LITERALLY STRING_LIT]
    rule 'alternation' => %w[ANY OF LPAREN alternatives RPAREN]
    rule 'alternatives' => %w[alternatives COMMA quantifiable]
    rule 'alternatives' => %w[alternatives quantifiable]
    rule 'alternatives' => 'quantifiable'
    rule 'grouping' => %w[LPAREN pattern RPAREN]
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