require_relative 'base_parser'
require_relative '../gfg/grm_flow_graph'
require_relative 'gfg_parsing'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Implementation of a parser that uses the Earley parsing algorithm.
    class GFGEarleyParser < BaseParser
      # The Grammar Flow graph for the given grammar
      attr_reader :gf_graph

      def initialize(aGrammar)
        super(aGrammar)
        @gf_graph = GFG::GrmFlowGraph.new(dotted_items)
      end

      # Parse a sequence of input tokens.
      # @param aTokenSequence [Array] Array of Tokens objects returned by a
      # tokenizer/scanner/lexer.
      # @return [Parsing] an object that embeds the parse results.
      def parse(aTokenSequence)
        result = GFGParsing.new(gf_graph, aTokenSequence)
        last_token_index = aTokenSequence.size
        if last_token_index == 0 && !grammar.start_symbol.nullable?
          return unexpected_empty_input(result)
        end

        (0..last_token_index).each do |i|
          result.chart[i].each do |entry|
            # Is entry of the form? [A => alpha . B beta, k]...
            next_symbol = entry.next_symbol
            if next_symbol && next_symbol.kind_of?(Syntax::NonTerminal)
              # ...apply the Call rule
              call_rule(result, entry, i)
            end

            exit_rule(result, entry, i) if entry.exit_entry?
            start_rule(result, entry, i) if entry.start_entry?
            end_rule(result, entry, i) if entry.end_entry?
          end
          if i < last_token_index
            scan_success = scan_rule(result, i)
            break unless scan_success
          end
        end
        
        result.done # End of parsing process
        return result
      end

      private

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
      #       add an entry to the next sigma set [A => α t . γ, i]
      def scan_rule(aParsing, aPosition)
        aParsing.scan_rule(aPosition)
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
