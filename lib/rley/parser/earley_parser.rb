require_relative '../syntax/grammar'
require_relative 'dotted_item'
require_relative 'parsing'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Implementation of a parser that uses the Earley parsing algorithm.
    class EarleyParser
      # The grammar of the language.
      attr_reader(:grammar)

      # The dotted items/rules for the productions of the grammar
      attr_reader(:dotted_items)

      # A Hash that defines the mapping: non-terminal => [start dotted items]
      attr_reader(:start_mapping)

      # A Hash that defines the mapping: dotted item => next dotted item
      # In other words, the 'next_mapping' allows to find the dotted item
      # after "advancing" the dot
      attr_reader(:next_mapping)


      def initialize(aGrammar)
        @grammar = aGrammar
        @dotted_items = build_dotted_items(grammar)
        @start_mapping = build_start_mapping(dotted_items)
        @next_mapping = build_next_mapping(dotted_items)
      end

      def parse(aTokenSequence)
        result = Parsing.new(start_dotted_item, aTokenSequence)
        last_token_index = aTokenSequence.size
        (0..last_token_index).each do |i|
          result.chart[i].each do |state|
            if state.complete?
              # parse reached end of production
              completion(result, state, i)
            else
              next_symbol = state.next_symbol
              if next_symbol.kind_of?(Syntax::NonTerminal)
                prediction(result, next_symbol, i)
              elsif i < last_token_index
                # Expecting a terminal symbol
                scanning(result, next_symbol, i)
              end
            end
          end
        end

        return result
      end

      private

      def build_dotted_items(aGrammar)
        items = []
        aGrammar.rules.each do |prod|
          rhs_size = prod.rhs.size
          if rhs_size == 0
            items << DottemItem.new(prod, 0)
          else
            items += (0..rhs_size).map { |i| DottedItem.new(prod, i) }
          end
        end

        return items
      end

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
      def start_dotted_item()
        # TODO: remove assumption that first dotted_item is 
        # for start production
        return dotted_items[0]
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
      # @param aNonTerminal [NonTerminal] a non-terminal symbol that 
      #   immediately follows a dot 
      #   (= is expected/predicted by the production rule)
      # @param aPosition [Fixnum] position in the input token sequence.
      def prediction(aParsing, aNonTerminal, aPosition)
        # Retrieve all start dotted items for productions
        # with aNonTerminal as its lhs
        items = start_mapping[aNonTerminal]
        items.each do |an_item|
          aParsing.push_state(an_item, aPosition, aPosition)
        end
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
      # @param Terminal [Terminal] a terminal symbol that 
      #   immediately follows a dot 
      # @param aPosition [Fixnum] position in the input token sequence.
      def scanning(aParsing, aTerminal, aPosition)
        aParsing.scanning(aTerminal, aPosition) do |item|
          next_mapping[item]
        end
      end

      # This method is called when a parse state at chart entry reaches 
      # the end of a production.
      # For every state in chart[aPosition] that is 
      # complete (i.e. of the form: { dotted_rule: X -> γ •, origin: j}),
      # Find states s in chart[j] of the 
      #  form {dotted_rule: Y -> α • X β, origin: i}
      #   In other words, rules that predicted the non-terminal X.
      # For each s, add to chart[aPosition] a state of the form
      #   { dotted_rule: Y → α X • β, origin: i})
      def completion(aParsing, aState, aPosition)
        aParsing.completion(aState, aPosition) do |item|
          next_mapping[item]
        end
      end
    end # class
  end # module
end # module

# End of file
