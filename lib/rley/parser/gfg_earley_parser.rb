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
      # @param aTraceLevel [Fixnum] The specified trace level.
      # The possible values are:
      # 0: No trace output (default case)
      # 1: Show trace of scanning and completion rules
      # 2: Same as of 1 with the addition of the prediction rules
      # @return [Parsing] an object that embeds the parse results.
      def parse(aTokenSequence, aTraceLevel = 0)
        tracer = ParseTracer.new(aTraceLevel, $stdout, aTokenSequence)
        result = GFGParsing.new(gf_graph, aTokenSequence, tracer)
        last_token_index = aTokenSequence.size
        (0..last_token_index).each do |i|
          handle_error(result) if result.chart[i].empty?
          result.chart[i].each do |entry|
            # Is entry of the form? [A => alpha . B beta, k]...
            next_symbol = entry.next_symbol
            if next_symbol && next_symbol.kind_of?(Syntax::NonTerminal)
              # ...apply the Call rule
              call_rule(result, entry, i, tracer)
            end

            exit_rule(result, entry, i, tracer) if entry.exit_entry?
            start_rule(result, entry, i, tracer) if entry.start_entry?
            end_rule(result, entry, i, tracer) if entry.end_entry?
          end
          scan_rule(result, i, tracer) if i < last_token_index
        end

        return result
      end

      private

      # Let the current sigma set be the ith parse entry set.
      # This method is invoked when an entry is added to the parse entry set
      # and is of the form [A => alpha . B beta, k].
      # Then the entry [.B, i] is added to the current sigma set.
      # Gist: when an entry expects the non-terminal symbol B, then
      # add an entry with start vertex .B
      def call_rule(aParsing, anEntry, aPosition, aTracer)
        if aTracer.level > 1
          puts "Chart[#{aPosition}] Call rule applied upon #{anEntry}:"
        end
        aParsing.call_rule(anEntry, aPosition)
      end

      # Let the current sigma set be the ith parse entry set.
      # This method is invoked when an entry is added to a parse entry set
      # and the entry is of the form [.B, i].
      # then for every rule B => γ in the grammar an entry [B => . γ, i]
      # is added to the current sigma set.
      # Gist: for an entry corresponding to a start vertex, add an entry
      # for each entry edge in the graph.
      def start_rule(aParsing, anEntry, aPosition, aTracer)
        if aTracer.level > 1
          puts "Chart[#{aPosition}] Start rule applied upon #{anEntry}:"
        end
        aParsing.start_rule(anEntry, aPosition)
      end

      # This method must be invoked when an entry is added to a parse entry set
      # and is of the form [B => γ ., k] (the dot is at the end of the
      # production. Then entry [B., k] is added to the current entry set.
      # Gist: for an entry corresponding to a reduced production, add an entry
      # for each exit edge in the graph.
      def exit_rule(aParsing, anEntry, aPosition, aTracer)
        if aTracer.level > 1
          puts "Chart[#{aPosition}] Exit rule applied upon #{anEntry}:"
        end
        aParsing.exit_rule(anEntry, aPosition)
      end

      # This method is invoked when an entry of the form [B., k]
      # is added to a parse entry set with index j.
      # then for every entry of the form [A => α . B γ, i] in the kth sigma set
      #   the entry [A => α B . γ, i] is added to the jth sigma set.
      def end_rule(aParsing, anEntry, aPosition, aTracer)
        if aTracer.level > 1
          puts "Chart[#{aPosition}] End rule applied upon #{anEntry}:"
        end
        aParsing.end_rule(anEntry, aPosition)
      end

      # Given that the terminal t is at the specified position,
      #   Locate all entries in the current sigma set that expect t:
      #     [A => α . t γ, i]
      #     and allow them to cross the edge, adding the node on the back side
      #     of the edge as an entry to the next sigma set:
      #       add an entry to the next sigma set [A => α t . γ, i]
      def scan_rule(aParsing, aPosition, aTracer)
        if aTracer.level > 1
          prefix = "Chart[#{aPosition}] Scan rule applied upon "
          puts prefix + aParsing.tokens[aPosition].to_s
        end
        aParsing.scan_rule(aPosition)
      end

      # Raise an exception to indicate a syntax error.
      def handle_error(aParsing)
        # Retrieve the first empty state set
        pos = aParsing.chart.sets.find_index(&:empty?)
        lexeme_at_pos = aParsing.tokens[pos - 1].lexeme
        puts "chart index: #{pos - 1}"
        terminals = aParsing.chart.sets[pos - 1].expected_terminals
        puts "count expected terminals #{terminals.size}"
        entries = aParsing.chart.sets[pos - 1].entries.map(&:to_s).join("\n")
        puts "Items #{entries}"
        term_names = terminals.map(&:name)
        err_msg = "Syntax error at or near token #{pos}"
        err_msg << ">>>#{lexeme_at_pos}<<<:\nExpected "
        err_msg << if terminals.size > 1
                     "one of: ['#{term_names.join("', '")}'],"
                   else
                     ": #{term_names[0]},"
                   end
        err_msg << " found a '#{aParsing.tokens[pos - 1].terminal.name}'"
        raise StandardError, err_msg + ' instead.'
      end
    end # class
  end # module
end # module

# End of file
