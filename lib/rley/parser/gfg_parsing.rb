require_relative 'gfg_chart'
require_relative 'error_reason'
require_relative 'parse_entry_tracker'
require_relative '../parse_rep/parse_forest_factory'
require_relative '../parse_rep/parse_tree_factory'


module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    class GFGParsing
      # The link to the grammar flow graph
      # @return [GFG::GrmFlowGraph] The GFG that drives the parsing
      attr_reader(:gf_graph)

      # The link to the chart object
      # @return [GFGChart]
      attr_reader(:chart)

      # The sequence of input token to parse
      # @return [Array<Lexical::Token>]
      attr_reader(:tokens)

      # A Hash with pairs of the form:
      # parse entry => [ antecedent parse entries ]
      # It associates to a every parse entry its antecedent(s), that is,
      # the parse entry/ies that causes the key parse entry to be created
      # with one the gfg rules
      # @return [Hash{ParseEntry => Array<ParseEntry>}]
      attr_reader(:antecedence)

      # @return [ErrorReason] The reason of a parse failure
      attr_reader(:failure_reason)

      # Constructor
      # @param theGFG [GFG::GrmFlowGraph] the Grammar Flow Graph
      # @param theTokens [Array<Token>] the array of input tokens
      def initialize(theGFG, theTokens)
        @gf_graph = theGFG
        @tokens = theTokens.dup
        @chart = GFGChart.new(tokens.size, gf_graph)
        @antecedence = Hash.new { |hash, key| hash[key] = [] }
        antecedence[chart[0].first]
      end

      # Let the current sigma set be the ith parse entry set.
      # This method is invoked when an entry is added to the parse entry set
      # and is of the form [A => alpha . B beta, k].
      # Then the entry [.B, i] is added to the current sigma set.
      # Gist: when an entry expects the non-terminal symbol B, then
      # add an entry with start vertex .B
      def call_rule(anEntry, aPosition)
        next_symbol = anEntry.next_symbol
        start_vertex = gf_graph.start_vertex_for[next_symbol]
        pos = aPosition
        size_before = chart[pos].size
        apply_rule(anEntry, start_vertex, pos, pos, :call_rule)

        if next_symbol.nullable? && anEntry.dotted_entry?
          size_after = chart[pos].size
          # ...apply the Nullable rule
          nullable_rule(anEntry, aPosition) if size_after == size_before
        end
      end

      # Let the current sigma set be the ith parse entry set.
      # This method is invoked when a dotted entry is added
      # to the parse entry set of the from [A => alpha . B beta, k]
      # and B is nullable
      # Then the following entries are added to the current sigma set:
      # [.B, i]
      # [B => ., i] TODO: what if indirectly nullable?
      # [B., i]
      # [A => alpha B . beta, k]
      def nullable_rule(anEntry, aPosition)
        next_symbol = anEntry.next_symbol
        pos = aPosition
        start = gf_graph.start_vertex_for[next_symbol]
        start_entry = apply_rule(anEntry, start, pos, pos, :nullable_rule)

        end_vertex = gf_graph.end_vertex_for[next_symbol]

        start.edges.each do |edge|
          succ = edge.successor # succ always an ItemVertex
          next if succ.dotted_item.production.generative?
          succ_entry = apply_rule(start_entry, succ, pos, pos, :nullable_rule)
          apply_rule(succ_entry, end_vertex, pos, pos, :nullable_rule)
        end

        curr_vertex = anEntry.vertex
        next_vertex = curr_vertex.shortcut.successor
        end_entry = push_entry(end_vertex, pos, pos, :nullable_rule)        
        apply_rule(end_entry, next_vertex, anEntry.origin, pos, :nullable_rule)
      end

      # Let the current sigma set be the ith parse entry set.
      # This method is invoked when an entry is added to a parse entry set
      # and the entry is of the form [.B, i].
      # then for every rule B => γ in the grammar an entry [B => . γ, i]
      # is added to the current sigma set.
      # Gist: for an entry corresponding to a start vertex, add an entry
      # for each entry edge in the graph.
      def start_rule(anEntry, aPosition)
        return unless anEntry.origin == aPosition

        anEntry.vertex.edges.each do |a_start_edge|
          successor = a_start_edge.successor
          apply_rule(anEntry, successor, aPosition, aPosition, :start_rule)
        end
      end

      # This method must be invoked when an entry is added to a parse entry set
      # and is of the form [B => γ ., k] (the dot is at the end of the
      # production. Then entry [B., k] is added to the current entry set.
      # Gist: for an entry corresponding to a reduced production, add an entry
      # for each exit edge in the graph.
      def exit_rule(anEntry, aPosition)
        lhs = anEntry.vertex.lhs
        end_vertex = gf_graph.end_vertex_for[lhs]
        apply_rule(anEntry, end_vertex, anEntry.origin, aPosition, :exit_rule)
      end

      # This method is invoked when an entry of the form [B., k]
      # is added to a parse entry set with index j.
      # then for every entry of the form [A => α . B γ, i] in the kth sigma set
      #   the entry [A => α B . γ, i] is added to the jth sigma set.
      def end_rule(anEntry, aPosition)
        nterm_k = anEntry.vertex.non_terminal
        origin_k = anEntry.origin
        set_k = chart[origin_k]

        # Retrieve all the entries that expect the non-terminal
        expecting_nterm_k = set_k.entries4n_term(nterm_k)
        expecting_nterm_k.each do |ntry|
          # Get the vertices after the expected non-terminal
          vertex_after_terminal = ntry.vertex.shortcut.successor
          origin = ntry.origin
          pos = aPosition
          apply_rule(anEntry, vertex_after_terminal, origin, pos, :end_rule)
        end
      end

      # Given that the terminal t is at the specified position,
      #   Locate all entries in the current sigma set that expect t:
      #     [A => α . t γ, i]
      #     and allow them to cross the edge, adding the node on the back side
      #     of the edge as an entry to the next sigma set:
      #       add an entry to the next sigma set [A => α t . γ, i]
      # returns true if next token matches the expectations, false otherwise.
      def scan_rule(aPosition)
        terminal = tokens[aPosition].terminal

        # Retrieve all the entries that expect the given terminal
        expecting_term = chart[aPosition].entries4term(terminal)

        # ... if the terminal isn't expected then we have an error
        if expecting_term.empty?
          unexpected_token(aPosition)
          return false
        end

        expecting_term.each do |ntry|
          # Get the vertices after the expected terminal
          ntry.vertex.edges.each do |an_edge|
            vertex_after_terminal = an_edge.successor
            origin = ntry.origin
            pos = aPosition + 1
            apply_rule(ntry, vertex_after_terminal, origin, pos, :scan_rule)
          end
        end

        return true
      end

      # Return true if the parse was successful (= input tokens
      # followed the syntax specified by the grammar)
      def success?()
        return false if @failure_reason
        return chart.accepting_entry ? true : false
      end

      # Return true if there are more than one complete state
      # for the same lhs and same origin in any state set.
      def ambiguous?()
        found = chart.sets.find { |set| !set.ambiguities.empty? }
        return !found.nil?
      end

      # Factory method. Builds a ParseForest from the parse result.
      # @return [ParseForest]
      def parse_forest()
        msg = <<-END_MSG
 Method Rley::Parser::GFGParsing.parse_forest is deprecated, call
 Rley::Engine::to_pforest. It will be removed June 1st
 or version 0.6.1 (whichever is first)
END_MSG
        # warn(msg)
        factory = ParseRep::ParseForestFactory.new(self)

        return factory.create
      end

      # Retrieve the very first parse entry added to the chart.
      # This entry corresponds to the start vertex of the GF graph
      # with origin equal to zero.
      def initial_entry()
        return chart.initial_entry
      end

      # Retrieve the accepting parse entry that represents
      # a complete, successful parse
      # After a successful parse, the last chart entry set
      # has an end parse entry that involves the start symbol
      def accepting_entry()
        return chart.accepting_entry
      end

      # Mark the parse as erroneous
      def faulty(aReason)
        @failure_reason = aReason
      end

      # A notification that the parsing reached an end
      def done()
        # Parse not successful and no reason identified
        # Assuming that parse failed because of a premature end
        premature_end unless success? || failure_reason
      end

      # Clean and normalize the object.
      # Call this method when the parsing is complete.
      def tidy_up!()
        antecedence.each_key do |entry|
          antecedence[entry].uniq!
        end
      end


      private

      # Parse error detected: all input tokens were consumed and
      # the parser didn't detect syntax error meanwhile but
      # could not reach the accepting state.
      def premature_end
        token_pos = tokens.size # One-based!
        last_token = tokens[-1]
        entry_set = chart.sets[tokens.size]
        expected = entry_set.expected_terminals

        reason = PrematureInputEnd.new(token_pos - 1, last_token, expected)
        faulty(reason)
      end

      # Parse error detected: input token doesn't match
      # the expectations set by grammar rules
      def unexpected_token(aPosition)
        unexpected = tokens[aPosition]
        expected = chart.sets[aPosition].expected_terminals
        reason = UnexpectedToken.new(aPosition, unexpected, expected)
        faulty(reason)
      end

      def apply_rule(antecedentEntry, aVertex, anOrigin, aPosition, aRuleId)
        consequent = push_entry(aVertex, anOrigin, aPosition, aRuleId)

        antecedence[consequent] << antecedentEntry

        # Invariant checks
        antecedents = antecedence[consequent]
        case aVertex
          when Rley::GFG::EndVertex
            # Rule: has 1..* antecedents, all of them are exit items
            antecedents.each do |antec|
              next if antec.exit_entry?
              msg_prefix = "Parse entry #{consequent}"
              msg_suffix = " has for antecedent #{antec}"              
              raise StandardError, msg_prefix + msg_suffix
            end
          
          when Rley::GFG::ItemVertex
            # Rule: has exactly one antecedent
            # if antecedents.size > 1
              # msg_prefix = "Parse entry #{consequent} | #{aPosition}"
              # msg = " has more than one antecedent:\n"
              # msg_suffix = antecedents.map(&:to_s).join("\n")
              # raise(StandardError, msg_prefix + msg + msg_suffix)
            # end
            
          when Rley::GFG::StartVertex
            # Rule: has 0..* antecedents, all of them are item vertices but not exit items
            antecedents.each do |antec|
              next if antec.dotted_entry? && !antec.end_entry?
              msg_prefix = "Parse entry #{consequent}"
              msg_suffix = " has for antecedent #{antec}"              
              raise StandardError, msg_prefix + msg_suffix
            end            
        end

        consequent.add_antecedent(antecedentEntry)
        return consequent
      end

      # Push a parse entry (vertex + origin) to the
      # chart entry with given index if it isn't yet in the chart entry.
      def push_entry(aVertex, anOrigin, aChartIndex, aReason)
        raise StandardError, 'Vertex may not be nil' if aVertex.nil?
        chart.push_entry(aVertex, anOrigin, aChartIndex, aReason)
      end

      # Factory method. Initializes a ParseForestBuilder object
      def forest_builder(anIndex)
        full_range = { low: 0, high: anIndex }
        start_production = chart.start_dotted_rule.production
        return ParseForestBuilder.new(start_production, full_range)
      end

      # Factory method. Creates and initializes a ParseEntryTracker instance.
      def new_entry_tracker()
        instance = ParseEntryTracker.new(chart.last_index)
        instance.parse_entry = accepting_entry

        return instance
      end
    end # class
  end # module
end # module

# End of file
