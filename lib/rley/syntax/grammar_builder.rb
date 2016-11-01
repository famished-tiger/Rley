require_relative 'verbatim_symbol'
require_relative 'literal'
require_relative 'non_terminal'
require_relative 'production'
require_relative 'grammar'

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # Builder GoF pattern. Builder pattern builds a complex object
    # (say, a grammar) from simpler objects (terminals and productions)
    # and using a step by step approach.
    class GrammarBuilder
      # The list of symbols of the language.
      # Grammar symbols are categorized into terminal (symbol)
      # and non-terminal (symbol).
      attr_reader(:symbols)

      # The list of production rules for the grammar to build
      attr_reader(:productions)

      def initialize()
        @symbols = {}
        @productions = []
      end
      
      # Retrieve a grammar symbol from its name.
      # Raise an exception if not found.
      # @param aSymbolName [String] the name of a symbol grammar.
      # @return [GrmSymbol] the retrieved symbol.
      def [](aSymbolName)
        return symbols[aSymbolName]
      end

      # Add the terminal symbols of the language
      # @param terminalSymbols [String or Terminal] one or more 
      # terminal symbols to add to the grammar.
      def add_terminals(*terminalSymbols)
        new_symbs = build_symbols(Terminal, terminalSymbols)
        symbols.merge!(new_symbs)
      end


      # Add a production rule in the grammar.
      # @param aProductionRepr [Hash] A Hash-based representation of the 
      # production. It consists of a key-value pair of the form: 
      # String => Array.
      #   Where the key is the name of the non-terminal appearing in the 
      #   left side of the rule. 
      #   The value, an Array, is a sequence of grammar symbol names.
      # The rule is created and inserted in the grammar.
      # Example:
      #   builder.add_production('A' => ['a', 'A', 'c'])
      def add_production(aProductionRepr)
        aProductionRepr.each_pair do |(lhs_name, rhs_repr)|
          lhs = get_nonterminal(lhs_name)
          case rhs_repr
            when Array
              rhs_constituents = rhs_repr.map { |name| get_nonterminal(name) }
            when String
              rhs_constituents = [ get_nonterminal(rhs_repr) ]
            when Terminal
              rhs_constituents = [ rhs_repr ]
          end
          new_prod = Production.new(lhs, rhs_constituents)
          productions << new_prod
        end
      end

      # Given the grammar symbols and productions added to the builder,
      # build the resulting grammar (if not yet done).
      def grammar()
        unless @grammar
          raise StandardError, 'No symbol found for grammar' if symbols.empty?
          if productions.empty?
            raise StandardError, 'No production found for grammar'
          end
          
          # Check that each non-terminal appears at least once in lhs.
          all_non_terminals = symbols.values.select { |s| s.is_a?(NonTerminal) }
          all_non_terminals.each do |n_term|
            next if productions.any? { |prod| n_term == prod.lhs }
            raise StandardError, "Nonterminal #{n_term.name} not rewritten"
          end

          @grammar = Grammar.new(productions.dup)
        end
        
        return @grammar
      end

      private

      # Add the given grammar symbols.
      # @param aClass [Class] The class of grammar symbols to instantiate.
      # @param theSymbols [Array] array of elements are treated as follows:
      #   if the element is already a grammar symbol, then it added as is,
      #   otherwise it is considered as the name of a grammar symbol
      # of the specified class to build.
      def build_symbols(aClass, theSymbols)
        symbs = {}
        theSymbols.each do |s|
          new_symbol = build_symbol(aClass, s)
          symbs[new_symbol.name] = new_symbol
        end

        return symbs
      end


      # If the argument is already a grammar symbol object then it is
      # returned as is. Otherwise, the argument is treated as a name
      # for a new instance of the given class.
      # @param aClass [Class] The class of grammar symbols to instantiate
      # @param aSymbolArg [GrmSymbol-like or String]
      # @return [Array] list of grammar symbols
      def build_symbol(aClass, aSymbolArg)
        a_symbol = if aSymbolArg.kind_of?(GrmSymbol)
                      aSymbolArg
                   else
                      aClass.new(aSymbolArg)
                   end

        return a_symbol
      end
      
      # Retrieve the non-terminal symbol with given name.
      # If it doesn't exist yet, then it is created on the fly.
      # @param aSymbolName [String] the name of the grammar symbol to retrieve
      # @return [NonTerminal]
      def get_nonterminal(aSymbolName)
        unless symbols.include? aSymbolName
          symbols[aSymbolName] = NonTerminal.new(aSymbolName)
        end
        return symbols[aSymbolName]
      end
      
    end # class
  end # module
end # module

# End of file
