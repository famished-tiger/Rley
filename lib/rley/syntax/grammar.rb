module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A grammar specifies the syntax of a language.
    #   Formally, a grammar has:
    #   One start symbol,
    #   One or more other production rules,
    #   Each production has a rhs that is a sequence of grammar symbols.
    #   Grammar symbols are categorized into
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

      # @param theProduction [Array of Production] the list of productions
      # of the grammar.
      def initialize(theProductions)
        @rules = []
        @symbols = []
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

      private

      # Validation method. Return the validated list of productions
      def validate_productions(theProductions)
        msg = 'A grammar must have at least one production'
        fail StandardError, msg if theProductions.nil? || theProductions.empty?
        return theProductions
      end

      def add_production(aProduction)
        @rules << aProduction
        the_lhs = aProduction.lhs
        @symbols << the_lhs unless @symbols.include? the_lhs

        # TODO: remove quadratic execution time
        aProduction.rhs.members.each do |symb|
          next if symbols.include? symb
          @symbols << symb
        end
      end

      # For each non-terminal determine whether it is nullable or not.
      def compute_nullable()
        # Do the obvious cases
        rules.each do |prod|
          next unless prod.rhs.empty?
          prod.lhs.nullable = true
        end
      end
=begin
        prods4nonterm = productions.group_by { |prod| prod.lhs }
          prods4nonterm.each_pair do |(lhs, prods)|        
        
        
        to_process = non_terminals.select { |nt| nt.nullable?.nil? }
        
        until to_process.empty? do

=end
    end # class
  end # module
end # module

# End of file
