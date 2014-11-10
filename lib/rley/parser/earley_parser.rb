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

        (0..aTokenSequence.size).each do |i|
          result.chart[i].each do |state|
            if state.complete?
              # parse reached end of production
              completion(result, state, i)
            else
              next_symbol = state.next_symbol
              if next_symbol.kind_of?(Syntax::NonTerminal)
                prediction(result, next_symbol, i)
              else
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


      def build_next_mapping(theDottedItems)
        mapping = {}
        theDottedItems.each_cons(2) do |(item1, item2)|
          next if item1.production != item2.production
          mapping[item1] = item2
        end

        return mapping
      end


      def start_dotted_item()
        # TODO: remove assumption that first dotted_item is for start production
        return dotted_items[0]
      end

      # procedure PREDICTOR((A → α•bβ, i), j, grammar)
      # for each (b → γ) in GRAMMAR-RULES-FOR(b, grammar) do
          # ADD-TO-SET((b → •γ, j), chart[j])
      # end
      def prediction(aParsing, aNonTerminal, aPosition)
        # Retrieve all start dotted items for productions
        # with aNonTerminal as its lhs
        items = start_mapping[aNonTerminal]
        items.each do |an_item|
          aParsing.push_state(an_item, aPosition, aPosition)
        end
      end

      # procedure SCANNER((A → α•B, i), j)
          # if B ⊂ PARTS-OF-SPEECH(word[j]) then
              # ADD-TO-SET((B → word[j], j), chart[j + 1])
          # end
      # Given k is current input position
      # If a is the next symbol in the input stream,
      # for every state in S(k) of the form (X → α • a β, j),
      # add (X → α a • β, j) to S(k+1).
      def scanning(aParsing, aTerminal, aPosition)
        aParsing.scanning(aTerminal, aPosition) { |item|
          next_mapping[item]
        }
      end
      
      # procedure COMPLETER((B → γ•, j), k)
      # for each (A → α•Bβ, i) in chart[j] do
          # ADD-TO-SET((A → αB•β, i), chart[k])
      # end
      # Parse position reached end of production
      # For every state in S(k) of the form (X → γ •, j), 
      # find states in S(j) of the form (Y → α • X β, i) 
      # and add (Y → α X • β, i) to S(k).
      def completion(aParsing, aState, aPosition)
        aParsing.completion(aState, aPosition) { |item|
          next_mapping[item]
        }
      end

    end # class

  end # module
end # module

# End of file