# frozen_string_literal: true

require_relative '../syntax/base_grammar_builder'

module Rley
  module Notation
    ########################################
    # Syntax for right-hand side of production rules
    builder = Rley::Syntax::BaseGrammarBuilder.new do
      add_terminals('LEFT_PAREN', 'RIGHT_PAREN') # For '(', ')' grouping delimiters
      add_terminals('LEFT_BRACE', 'RIGHT_BRACE') # For '{', '}' annotation delimiters
      add_terminals('QUESTION_MARK', 'STAR', 'PLUS') # For postfix quantifiers
      add_terminals('COMMA', 'ELLIPSIS')

      add_terminals('STR_LIT') # For string literal values
      add_terminals('INT_LIT') # For integer literal values
      add_terminals('SYMBOL') # Grammar symbols
      add_terminals('KEY') # Key literal

      rule('notation' => 'rhs')
      rule('rhs' => 'member_seq').tag 'sequence'
      rule('rhs' => [])
      rule('member_seq' => 'member_seq member').tag 'more_members'
      rule('member_seq' => 'member').tag 'one_member'
      rule('member' => 'strait_member')
      rule('member' => 'quantified_member')
      rule('strait_member' => 'base_member')
      rule('strait_member' => 'base_member annotation').tag 'annotated_member'
      rule('base_member' => 'SYMBOL').tag 'symbol'
      rule('base_member' => 'LEFT_PAREN member_seq RIGHT_PAREN').tag 'grouping'
      rule('quantified_member' => 'base_member quantifier').tag 'quantified_member'
      rule('quantifier' => 'QUESTION_MARK').tag 'question_mark'
      rule('quantifier' => 'STAR').tag 'star'
      rule('quantifier' => 'PLUS').tag 'plus'
      rule('annotation' => 'LEFT_BRACE mapping RIGHT_BRACE').tag 'annotation'
      rule('mapping' => 'mapping COMMA key_value').tag 'more_pairs'
      rule('mapping' => 'key_value').tag 'one_pair'
      rule('key_value' => 'KEY value').tag 'raw_pair'
      rule('value' => 'STR_LIT')
      rule('value' => 'INT_LIT')
      rule('value' => 'range')
      rule('range' => 'INT_LIT ELLIPSIS INT_LIT').tag 'bound_range'
      rule('range' => 'INT_LIT ELLIPSIS')
    end

    # And now build the Rley Grammar Notation (RGN) grammar...
    RGNGrammar = builder.grammar
  end # module
end # module