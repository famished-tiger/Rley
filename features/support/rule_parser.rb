# frozen_string_literal: true

require 'strscan'
require_relative '../../lib/rley/syntax/grammar_builder'
require_relative '../../spec/rley/support/grammar_helper'

module Rley4Cuke # Use the module as a namespace
  module RuleParser # Mixin module
    include GrammarHelper

    # Syntax: one grammar rule per line
    # NonTerminalSymbol '=>' Symbol+
    # | NonTerminalSymbol '=>' '[' ']'
    # Symbol ::= TerminalSymbol
    # | NonTerminalSymbol
    # TerminalSymbol ::= a single lower letter
    def parse_rules(grammarRules)
      raw_rules = grammarRules.split(/\n|\r\n/).map(&:strip)
      raw_rules.delete_if(&:empty?)

      rule_tokens = raw_rules.map(&:split)
      rule_tokens.each { |row| validate_tokenized_rule(row) }
    end

    def build_grammar(tokenizedRules)
      terminals = extract_terminals(tokenizedRules)
      formatted_rules = format_rules(tokenizedRules)
      builder = Rley::Syntax::GrammarBuilder.new
      builder.add_terminals(*terminals)
      formatted_rules.each do |(lhs, rhs_args)|
         builder.add_production(lhs => rhs_args)
      end

      builder.grammar
    end

    private

    # rubocop: disable Lint/UselessAssignment
    def validate_tokenized_rule(ruleTokens)
      # Rule: lhs of production must be a non-terminal symbol
      msg1 = 'Symbol at left-hand side must start with a capital letter'
      raise StandardError, msg1 unless ruleTokens[0] =~ /^[A-Z]/

      # Rule: lhs and rhs must be separated by an arrow =>
      msg2 = "Expected '=>' instead of '#{ruleTokens[1]}'"
      raise StandardError, msg2 if ruleTokens[1] != '=>'
    end

    # Find all the terminal symbols occurring in the grammar rules
    def extract_terminals(tokenizedRules)
      terminals = tokenizedRules.reduce([]) do |sub_result, token_row|
        sub_result += token_row.grep(/^[a-z]/)
      end

      terminals.uniq
    end
    # rubocop: enable Lint/UselessAssignment

    # Re-format the rules into a two-element array of the form:
    # [lhs, [rhs symbols array] ]
    # In case of an empty rhs, then: [lhs, []]
    def format_rules(tokenizedRules)
      tokenizedRules.dup.map do |tokens|
        tokens.delete_at(1) # Remove the arrow '=>'
        lhs = tokens.shift
        if tokens.length == 1 && tokens[0] == '[]'
          result = [lhs, []]
        else
          result = [lhs, tokens]
        end
        result
      end
    end
  end # module
end # module

=begin
obj = Object.new
obj.extend(Rley4Cuke::RuleParser)

source = <<-STOP_HERE
  Phi => S
  S => A T
  S => a T
  A => a
  A => B A
  B => []
  T => b b b
STOP_HERE

tokenized_rules = obj.parse_rules(source)
pp obj.build_grammar(tokenized_rules)

=end
