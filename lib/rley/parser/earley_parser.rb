require_relative '../syntax/grammar'
require_relative 'dotted_item'
require_relative 'parsing'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
  
    # Implementation of a parser that uses the Earley parsing algorithm.
    class EarleyParser
      # The grammar of the language.
      attr_reader(:grammar)
      
      # The dotted items for the productions of the grammar
      attr_reader(:dotted_items)
      
      
      def initialize(aGrammar)
        @grammar = aGrammar
        @dotted_items = build_dotted_items(aGrammar)
      end
      
      def parse(aTokenSequence)
        result = Parsing.new(start_dotted_item, aTokenSequence)
        
        (0..aTokenSequence.size).each do |i|
          result.chart[i].each do |state|
            if state.complete?  # parse reached end of production
              completer(state, i)
            else
              if state.next_symbol.kind_of?(Syntax::NonTerminal)
                predictor(state, i)
              else
                scanner(state, i)
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
      
      def start_dotted_item()
        return dotted_items[0]
      end
      
      # procedure PREDICTOR((A → α•bβ, i), j, grammar)
      # for each (b → γ) in GRAMMAR-RULES-FOR(b, grammar) do
          # ADD-TO-SET((b → •γ, j), chart[j])
      # end
      def predictor(aState, aPosition)
      end
      
      # procedure ADD-TO-SET(state, chart-entry)
      # if state is not already in chart-entry then
        # PUSH(state, chart-entry)
      # end
      # TODO

    end # class
  
  end # module
end # module

# End of file