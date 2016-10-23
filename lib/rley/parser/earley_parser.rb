require_relative 'base_parser'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Implementation of a parser that uses the Earley parsing algorithm.  
    class EarleyParser < BaseParser
      # A Hash that defines the mapping: non-terminal => [start dotted items]
      attr_reader(:start_mapping)

      # A Hash that defines the mapping: dotted item => next dotted item
      # In other words, the 'next_mapping' allows to find the dotted item
      # after "advancing" the dot
      attr_reader(:next_mapping)
      
      def initialize(aGrammar)
        super(aGrammar)
        @start_mapping = build_start_mapping(dotted_items)
        @next_mapping = build_next_mapping(dotted_items)
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
        result = Parsing.new(start_dotted_items, aTokenSequence, tracer)
        last_token_index = aTokenSequence.size
        (0..last_token_index).each do |i|
          handle_error(result) if result.chart[i].empty?
          predicted = Set.new
          result.chart[i].each do |state|
            if state.complete? # End of production reached?
              completion(result, state, i, tracer)
            else
              next_symbol = state.next_symbol
              if next_symbol.kind_of?(Syntax::NonTerminal)
                unless predicted.include? next_symbol
                  prediction(result, state, next_symbol, i, tracer)
                  predicted << next_symbol # Avoid repeated predictions
                end
              elsif i < last_token_index
                # Expecting a terminal symbol
                scanning(result, next_symbol, i, tracer)
              end
            end
          end
        end

        return result
      end

      private

      # Create a Hash with pairs of the kind:
      # non-terminal => [start dotted items]
      def build_start_mapping(theDottedItems)
        mapping = {}
        theDottedItems.each do |item|
          next unless item.at_start?

          lhs_symbol = item.lhs
          map_entry = mapping.fetch(lhs_symbol, [])
          map_entry << item
          mapping[lhs_symbol] = map_entry
        end

        return mapping
      end

      # Create a Hash with pairs of the kind:
      # dotted item => next dotted item
      # next dotted item uses same production and the dot
      # position is advanced by one symbol
      def build_next_mapping(theDottedItems)
        mapping = {}
        theDottedItems.each_cons(2) do |(item1, item2)|
          next if item1.production != item2.production
          mapping[item1] = item2
        end

        return mapping
      end

      # The dotted item for the start production and
      # with the dot at the beginning of the rhs
      def start_dotted_items()
        start_symbol = grammar.start_symbol
        start_items = dotted_items.select do |anItem|
          (anItem.lhs == start_symbol) && anItem.at_start?
        end
        
        return start_items
      end

      
      # This method is called when a parse state for chart entry at position 
      # 'pos' expects as next symbol a non-terminal.
      # Given a predicted non-terminal 'nt' and a current token position
      # 'pos':
      # For each production with 'nt' as lhs, retrieve their corresponding
      # initial dotted rules nt -> . xxxx
      # For retrieved dotted rule, add a parse state to the chart entry 
      # at 'pos': <initial dotted rule, pos, pos>
      # In short, one adds states to chart[pos], one per production that
      # specifies how to reduce some input into the predicted nt (non-terminal)
      # A prediction corresponds to a potential expansion of a nonterminal 
      # in a left-most derivation. 
      # @param aParsing [Parsing] the object that encapsulates the results
      #   result of the parsing process
      # @param aState [ParseState] current parse state being processed
      # @param aNonTerminal [NonTerminal] a non-terminal symbol that 
      #   immediately follows a dot 
      #   (= is expected/predicted by the production rule)
      # @param aPosition [Fixnum] position in the input token sequence.
      def prediction(aParsing, aState, aNonTerminal, aPosition, aTracer)
        if aTracer.level > 1
          puts "Chart[#{aPosition}] Prediction(s) from #{aState}:"
        end
        # Retrieve all start dotted items for productions
        # with aNonTerminal as its lhs
        items = start_mapping[aNonTerminal]
        items.each do |an_item|
          aParsing.push_state(an_item, aPosition, aPosition, :prediction)
        end

        return unless aNonTerminal.nullable?
        # Ayock-Horspool trick for nullable rules
        next_item = next_mapping[aState.dotted_rule]
        aParsing.push_state(next_item, aState.origin, aPosition, :prediction)
      end

      # This method is called when a parse state for chart entry at position 
      # 'pos' expects a terminal as next symbol.
      # If the input token matches the terminal symbol then:
      # Retrieve all parse states for chart entry at 'aPosition'
      # that have the given terminal as next symbol.
      # For each s of the above states, push to chart entry aPosition + 1 
      # a new state like: <next dotted rule, s.origin, aPosition + 1>
      # In other words, we place the dotted rules in the next state set 
      # such that the dot appears after terminal.
      # @param aParsing [Parsing] the object that encapsulates the results
      #   result of the parsing process
      # @param aTerminal [Terminal] a terminal symbol that 
      #   immediately follows a dot 
      # @param aPosition [Fixnum] position in the input token sequence.
      def scanning(aParsing, aTerminal, aPosition, aTracer)
        if aTracer.level > 1
          prefix = "Chart[#{aPosition}] Scanning of terminal "
          suffix = "#{aTerminal.name}:"
          puts prefix + suffix
        end
        aParsing.scanning(aTerminal, aPosition) do |item|
          next_mapping[item]
        end
      end

      # This method is called when a parse state at chart entry reaches 
      # the end of a production.
      # For every state in chart[aPosition] that is 
      # complete (i.e. of the form: { dotted_rule: X -> γ •, origin: j}),
      # Find states s in chart[j] of the 
      #  form { dotted_rule: Y -> α • X β, origin: i}
      #   In other words, rules that predicted the non-terminal X.
      # For each s, add to chart[aPosition] a state of the form
      #   { dotted_rule: Y → α X • β, origin: i})
      def completion(aParsing, aState, aPosition, aTracer)
        if aTracer.level > 1
          puts "Chart[#{aPosition}] Completion of state #{aState}:"
        end
        aParsing.completion(aState, aPosition) do |item|
          next_mapping[item]
        end
      end
      
      # Raise an exception to indicate a syntax error.
      def handle_error(aParsing)
        # Retrieve the first empty state set
        pos = aParsing.chart.state_sets.find_index(&:empty?)
        lexeme_at_pos = aParsing.tokens[pos - 1].lexeme
        
        terminals = aParsing.chart.state_sets[pos - 1].expected_terminals
        term_names = terminals.map(&:name)
        err_msg = "Syntax error at or near token #{pos}"
        err_msg << ">>>#{lexeme_at_pos}<<<:\nExpected "
        if terminals.size > 1
          err_msg << "one of: ['#{term_names.join("', '")}'],"
        else
           err_msg << ": #{term_names[0]},"
        end
        err_msg << " found a '#{aParsing.tokens[pos - 1].terminal.name}'"
        fail StandardError, err_msg + ' instead.'
      end
    end # class
  end # module
end # module

# End of file
