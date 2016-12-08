require 'set'

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A grammar specifies the syntax of a language.
    #   Formally, a grammar has: 
    #   * One start symbol,
    #   * One or more other production rules,
    #   * Each production has a rhs that is a sequence of grammar symbols.
    #   * Grammar symbols are categorized into 
    #   -terminal symbols
    #   -non-terminal symbols
    class Grammar
      # A non-terminal symbol that represents all the possible strings
      # in the language.
      attr_reader(:start_symbol)

      # The list of production rules for the language.
      attr_reader(:rules)

      # The list of grammar symbols in the language.
      attr_reader(:symbols)

      # A Hash with pairs of the kind: symbol name => grammar symbol
      attr_reader(:name2symbol)

      # @param theProductions [Array<Production>] productions of the grammar.
      def initialize(theProductions)
        @rules = []
        @symbols = []
        @name2symbol = {}
        valid_productions = validate_productions(theProductions)
        # TODO: use topological sorting
        @start_symbol = valid_productions[0].lhs
        valid_productions.each { |prod| add_production(prod) }
        compute_nullable
      end

      # @return [Array] The list of non-terminals in the grammar.
      def non_terminals()
        return symbols.select { |s| s.kind_of?(NonTerminal) }
      end

      # @return [Production] The start production of the grammar (i.e.
      #   the rule that specifies the syntax for the start symbol.
      def start_production()
        return rules[0]
      end

      private

      # Validation method. Return the validated list of productions
      def validate_productions(theProductions)
        msg = 'A grammar must have at least one production'
        raise StandardError, msg if theProductions.nil? || theProductions.empty?
        return theProductions
      end

      def add_production(aProduction)
        @rules << aProduction
        the_lhs = aProduction.lhs
        add_symbol(the_lhs)

        # TODO: remove quadratic execution time
        aProduction.rhs.each { |symb| add_symbol(symb) }
      end


      # For each non-terminal determine whether it is nullable or not.
      # A nullable nonterminal is a nonterminal that can match an empty string.
      def compute_nullable()
        non_terminals.each { |nterm| nterm.nullable = false }
        nullable_sets = [ direct_nullable ]

        # Drop productions with one terminal in rhs or with a nullable lhs
        filtered_rules = rules.reject do |prod|
          prod.lhs.nullable? || prod.rhs.find do |symb|
            symb.kind_of?(Terminal)
          end
        end

        (1...non_terminals.size).each do |i|
          new_nullables = Set.new
          filtered_rules.each do |a_prod|
            rhs_nullable = a_prod.rhs.members.all? do |symb|
              nullable_sets[i - 1].include? symb
            end
            if rhs_nullable
              a_prod.lhs.nullable = true
              new_nullables << a_prod.lhs
            end
          end
          break if new_nullables.empty?
          filtered_rules.reject! { |prod| prod.lhs.nullable? }
          nullable_sets[i] = nullable_sets[i - 1].merge(new_nullables)
        end
      end


      # Return the set of nonterminals which have one of their
      # production rules empty
      def direct_nullable()
        nullable = Set.new
        # Direct nullable nonterminals correspond to empty productions
        rules.each do |prod|
          next unless prod.empty?
          prod.lhs.nullable = true
          nullable << prod.lhs
        end

        return nullable
      end

      def add_symbol(aSymbol)
        its_name = aSymbol.name
        return if name2symbol.include? its_name

        @symbols << aSymbol
        @name2symbol[its_name] = aSymbol
      end
    end # class
  end # module
end # module

# End of file
