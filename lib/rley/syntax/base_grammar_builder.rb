# frozen_string_literal: true

require 'set'
require_relative 'terminal'
require_relative 'non_terminal'
require_relative 'literal'
require_relative 'verbatim_symbol'
require_relative 'production'
require_relative 'grammar'

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # Builder GoF pattern. Builder builds a complex object
    #   (say, a grammar) from simpler objects (terminals and productions)
    #   and using a step by step approach.
    class BaseGrammarBuilder
      # @return [Hash{String, GrmSymbol}] The mapping of grammar symbol names
      #   to the matching grammar symbol object.
      attr_reader(:symbols)

      # @return [Array<Production>] The list of production rules for
      #   the grammar to build.
      attr_reader(:productions)

      # Creates a new grammar builder.
      # @param aBlock [Proc] code block used to build the grammar.
      # @example Building a tiny English grammar
      #   builder = Rley::Syntax::GrammarBuilder.new do
      #     add_terminals('n', 'v', 'adj', 'det')
      #     rule 'S' => %w[NP VP]
      #     rule 'VP' => %w[v NP]
      #     rule 'NP' => %w[det n]
      #     rule 'NP' => %w[adj NP]
      #   end
      #   tiny_eng = builder.grammar
      def initialize(&aBlock)
        @symbols = {}
        @productions = []

        instance_exec(&aBlock) if block_given?
      end

      # Retrieve a grammar symbol from its name.
      # Raise an exception if not found.
      # @param aSymbolName [String] the name of a grammar symbol.
      # @return [GrmSymbol] the retrieved symbol object.
      def [](aSymbolName)
        symbols[aSymbolName]
      end

      # Add the given terminal symbols to the grammar of the language
      # @param terminalSymbols [String or Terminal] 1..* terminal symbols.
      # @return [void]
      def add_terminals(*terminalSymbols)
        new_symbs = build_symbols(Terminal, terminalSymbols)
        symbols.merge!(new_symbs)
      end

      # Add a production rule in the grammar given one
      # key-value pair of the form: String => Array.
      #   Where the key is the name of the non-terminal appearing in the
      #   left side of the rule.
      #   The value, an Array, is a sequence of grammar symbol names.
      # The rule is created and inserted in the grammar.
      # @example Equivalent call syntaxes
      #   builder.add_production('A' => ['a', 'A', 'c'])
      #   builder.rule('A' => ['a', 'A', 'c']) # 'rule' is a synonym
      #   builder.rule('A' => %w[a A  c]) # Use %w syntax for Array of String
      #   builder.rule 'A' => %w[a A  c]  # Call parentheses are optional
      # @param aProductionRepr [Hash{String, Array<String>}]
      #   A Hash-based representation of a production.
      # @return [Production] The created Production instance
      def add_production(aProductionRepr)
        aProductionRepr.each_pair do |(lhs_name, rhs_repr)|
          lhs = get_grm_symbol(lhs_name)
          case rhs_repr
            when Array
              rhs_members = rhs_repr.map { |name| get_grm_symbol(name) }
            when String
              rhs_lexemes = rhs_repr.scan(/\S+/)
              rhs_members = rhs_lexemes.map { |name| get_grm_symbol(name) }
            when Terminal
              rhs_members = [rhs_repr]
          end
          new_prod = Production.new(lhs, rhs_members)
          productions << new_prod
        end

        return productions.last
      end

      # Given the grammar symbols and productions added to the builder,
      # build the resulting grammar (if not yet done).
      # @return [Grammar] the created grammar object.
      def grammar
        unless @grammar
          raise StandardError, 'No symbol found for grammar' if symbols.empty?
          if productions.empty?
            raise StandardError, 'No production found for grammar'
          end

          # Check that each terminal appears at least in a rhs of a production
          all_terminals = symbols.values.select do |a_symb|
            a_symb.kind_of?(Terminal)
          end
          in_use = Set.new
          productions.each do |prod|
            prod.rhs.members.each do |symb|
              in_use << symb if symb.kind_of?(Syntax::Terminal)
            end
          end

          unused = all_terminals.reject { |a_term| in_use.include?(a_term) }
          unless unused.empty?
            suffix = "#{unused.map(&:name).join(', ')}."
            raise StandardError, "Useless terminal symbol(s): #{suffix}"
          end

          @grammar = Grammar.new(productions.dup)
        end

        return @grammar
      end

      # When a symbol, say symb, in a rhs is followed by a '+' modifier,
      # then a rule will be generated with a lhs named symb + suffix_plus
      def suffix_plus
        '_plus'
      end

      def suffix_plus_more
        'base_plus_more'
      end

      def suffix_plus_last
        'base_plus_last'
      end

      alias rule add_production

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
        if aSymbolArg.kind_of?(GrmSymbol)
          aSymbolArg
        else
          aClass.new(aSymbolArg)
        end
      end

      # Retrieve the non-terminal symbol with given name.
      # If it doesn't exist yet, then it is created on the fly.
      # @param aSymbolName [String] the name of the grammar symbol to retrieve
      # @return [NonTerminal]
      def get_grm_symbol(aSymbolName)
        unless aSymbolName.end_with?('+') && aSymbolName.length > 1
          name = aSymbolName
        else
          name = aSymbolName.chop
          case aSymbolName[-1]
            when '+'
              name_modified = "#{name}#{suffix_plus}"
              unless symbols.include? name_modified
                symbols[name_modified] = NonTerminal.new(name_modified)
                rule(name_modified => [name_modified, name]).as suffix_plus_more
                rule(name_modified => name).as suffix_plus_last
              end
              name = name_modified
            else
              err_msg = "Unknown symbol modifier #{aSymbolName[-1]}"
              raise NotImplementedError, err_msg
          end
        end

        symbols[name] = NonTerminal.new(name) unless symbols.include? name

        symbols[name]
      end
    end # class
  end # module
end # module

# End of file
