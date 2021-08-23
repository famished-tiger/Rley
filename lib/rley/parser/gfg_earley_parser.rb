# frozen_string_literal: true

require_relative '../base/base_parser'
require_relative '../gfg/grm_flow_graph'
require_relative 'gfg_parsing'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Implementation of a parser that uses the Earley parsing algorithm.
    class GFGEarleyParser < Base::BaseParser
      # The Grammar Flow graph generated from the provided grammar.
      # @return [GFG::GrmFlowGraph] The GFG that drives the parsing
      attr_reader :gf_graph

      # Constructor.
      # @param aGrammar [Syntax::Grammar] The grammar of the language to parse.
      def initialize(aGrammar)
        super(aGrammar)
        @gf_graph = GFG::GrmFlowGraph.new(dotted_items)
      end

      # Parse a sequence of input tokens.
      # @param aTokenSequence [Array] Array of Tokens objects returned by a
      # tokenizer/scanner/lexer.
      # @return [GFGParsing] an object that embeds the parse results.
      def parse(aTokenSequence)
        result = GFGParsing.new(gf_graph)
        token_count = aTokenSequence.size
        if token_count.zero? && !grammar.start_symbol.nullable?
          return unexpected_empty_input(result)
        end

        aTokenSequence.each_with_index do |token, i|
          parse_for_token(result, i)
          if token.terminal.kind_of?(String)
            symb = grammar.name2symbol[token.terminal]
            token.instance_variable_set(:@terminal, symb)
          end
          scan_success = scan_rule(result, i, token)
          break unless scan_success
        end
        parse_for_token(result, token_count) unless result.failure_reason

        result.done # End of parsing process
        return result
      end

      private

      def parse_for_token(result, index)
        result.chart[index].each do |entry|
          # Is entry of the form? [A => alpha . B beta, k]...
          next_symbol = entry.next_symbol
          if next_symbol.kind_of?(Syntax::NonTerminal)
            # ...apply the Call rule
            call_rule(result, entry, index)
          end

          exit_rule(result, entry, index) if entry.exit_entry?
          start_rule(result, entry, index) if entry.start_entry?
          end_rule(result, entry, index) if entry.end_entry?
        end
      end

      # Let the current sigma set be the ith parse entry set.
      # This method is invoked when an entry is added to the parse entry set
      # and is of the form [A => alpha . B beta, k].
      # Then the entry [.B, i] is added to the current sigma set.
      # Gist: when an entry expects the non-terminal symbol B, then
      # add an entry with start vertex .B
      def call_rule(aParsing, anEntry, aPosition)
        aParsing.call_rule(anEntry, aPosition)
      end

      # Let the current sigma set be the ith parse entry set.
      # This method is invoked when an entry is added to a parse entry set
      # and the entry is of the form [.B, i].
      # then for every rule B => γ in the grammar an entry [B => . γ, i]
      # is added to the current sigma set.
      # Gist: for an entry corresponding to a start vertex, add an entry
      # for each entry edge in the graph.
      def start_rule(aParsing, anEntry, aPosition)
        aParsing.start_rule(anEntry, aPosition)
      end

      # This method must be invoked when an entry is added to a parse entry set
      # and is of the form [B => γ ., k] (the dot is at the end of the
      # production. Then entry [B., k] is added to the current entry set.
      # Gist: for an entry corresponding to a reduced production, add an entry
      # for each exit edge in the graph.
      def exit_rule(aParsing, anEntry, aPosition)
        aParsing.exit_rule(anEntry, aPosition)
      end

      # This method is invoked when an entry of the form [B., k]
      # is added to a parse entry set with index j.
      # then for every entry of the form [A => α . B γ, i] in the kth sigma set
      #   the entry [A => α B . γ, i] is added to the jth sigma set.
      def end_rule(aParsing, anEntry, aPosition)
        aParsing.end_rule(anEntry, aPosition)
      end

      # Given that the terminal t is at the specified position,
      #   Locate all entries in the current sigma set that expect t:
      #     [A => α . t γ, i]
      #     and allow them to cross the edge, adding the node on the back side
      #     of the edge as an entry to the next sigma set:
      #       add an entry to the next sigma set [A => α t . γ, i + 1]
      def scan_rule(aParsing, aPosition, aToken)
        aParsing.scan_rule(aPosition, aToken)
      end

      # Parse error detected: no input tokens provided while the grammar
      # forbids this this.
      def unexpected_empty_input(aParsing)
        aParsing.faulty(NoInput.new)
        return aParsing
      end
    end # class
  end # module
end # module

# End of file
