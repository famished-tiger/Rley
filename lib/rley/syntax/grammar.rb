# frozen_string_literal: true

require_relative '../rley_error'

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A grammar specifies the syntax of a language.
    #   Formally, a grammar has:
    #   * One start symbol,
    #   * One or more other production rules,
    #   * Each production has a rhs that is a sequence of grammar symbols.
    #   * Grammar symbols are categorized into:
    #     -terminal symbols
    #     -non-terminal symbols
    class Grammar
      # A non-terminal symbol that represents all the possible strings
      # in the language.
      # @return [NonTerminal] Start symbol of the grammar.
      attr_reader(:start_symbol)

      # The list of production rules for the language.
      # @return [Array<Production>] Array of productions for the grammar.
      attr_reader(:rules)

      # The list of grammar symbols in the language.
      # @return [Array<GrmSymbol>] The terminal and non-terminal symbols.
      attr_reader(:symbols)

      # A Hash that maps symbol names to their grammar symbols
      # @return [Hash{String => GrmSymbol}]
      attr_reader(:name2symbol)

      # @param theProductions [Array<Production>] productions of the grammar.
      def initialize(theProductions)
        @rules = []
        @symbols = []
        @name2symbol = {}
        valid_productions = validate_productions(theProductions)
        valid_productions.each do |prod|
          add_production(prod)
          name_production(prod)
        end
        diagnose

        # TODO: use topological sorting
        @start_symbol = valid_productions[0].lhs
      end

      # @return [Array] The list of non-terminals in the grammar.
      def non_terminals
        @non_terminals ||= symbols.select { |s| s.kind_of?(NonTerminal) }
      end

      # @return [Production] The start production of the grammar (i.e.
      #   the rule that specifies the syntax for the start symbol.
      def start_production
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

        aProduction.rhs.each { |symb| add_symbol(symb) }
        aProduction
      end

      # If the production is anonymous, then assign it
      # a default name
      def name_production(aProduction)
        return unless aProduction.name.nil?

        index = rules.find_index(aProduction)
        prefix = aProduction.lhs.name.dup
        previous = index.zero? ? nil : rules[index - 1]
        if previous.nil? || previous.lhs != aProduction.lhs
          suffix = '_0'
        else
          prev_serial = previous.name.match(/_(\d+)$/)
          if prev_serial
            suffix = "_#{prev_serial[1].to_i + 1}"
          else
            suffix = '_0'
          end
        end

        aProduction.name = prefix + suffix
      end

      # Perform some check of the grammar.
      def diagnose
        mark_undefined
        mark_generative
        compute_nullable
      end

      # Check that each non-terminal appears at least once in lhs.
      # If it is not the case, then mark it as undefined
      def mark_undefined
        defined = Set.new

        # Defined non-terminals appear at least once as lhs of a production
        rules.each { |prod| defined << prod.lhs }
        defined.each { |n_term| n_term.undefined = false }

        # Retrieve all non-terminals that aren't marked as non-undefined
        undefined = non_terminals.select { |n_term| n_term.undefined?.nil? }

        undefined.each { |n_term| n_term.undefined = true }
      end

      # Mark all non-terminals and production rules as
      # generative or not.
      # A production is generative when it can derive a string of terminals.
      # A production is therefore generative when all its rhs members are
      # themselves generatives.
      # A non-terminal is generative if at least one of its defining production
      # is itself generative.
      def mark_generative
        curr_marked = []

        # Iterate until no new rule can be marked.
        loop do
          prev_marked = curr_marked.dup

          rules.each do |a_rule|
            next unless a_rule.generative?.nil?

            if a_rule.empty?
              a_rule.generative = false
              curr_marked << a_rule
              could_mark_nterm_generative(a_rule)
              next
            end

            last_considered = nil
            a_rule.rhs.members.each do |symbol|
              last_considered = symbol
              break unless symbol.generative?
            end
            next if last_considered.generative?.nil?

            a_rule.generative = last_considered.generative?
            curr_marked << a_rule
            could_mark_nterm_generative(a_rule)
          end
          break if prev_marked.size == curr_marked.size
        end

        # The nonterminals that are not marked yet are non-generative
        non_terminals.each do |nterm|
          nterm.generative = false if nterm.generative?.nil?
        end
      end

      # Given a production rule with given non-terminal
      # Check whether that non-terminal should be marked
      # as generative or not.
      # A non-terminal may be marked as generative if at
      # least one of its defining production is generative.
      def could_mark_nterm_generative(aRule)
        nterm = aRule.lhs

        # non-terminal already marked? If yes, nothing more to do...
        return unless nterm.generative?.nil?

        defining_rules = rules_for(nterm) # Retrieve all defining productions

        all_false = true
        defining_rules.each do |prod|
          if prod.generative?
            # One generative rule found!
            nterm.generative = true
            all_false = false
            break
          elsif prod.generative?.nil?
            all_false = false
          end
        end
        nterm.generative = false if all_false
      end

      # For each non-terminal determine whether it is nullable or not.
      # A nullable nonterminal is a nonterminal that can match an empty string.
      def compute_nullable
        non_terminals.each { |nterm| nterm.nullable = false }
        nullable_sets = [direct_nullable]

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

        mark_nullable
      end

      # Return the set of nonterminals which have one of their
      # production rules empty
      def direct_nullable
        nullables = Set.new
        # Direct nullable nonterminals correspond to empty productions
        rules.each do |prod|
          next unless prod.empty?

          prod.lhs.nullable = true
          nullables << prod.lhs
        end

        nullables
      end

      # For each prodction determine whether it is nullable or not.
      # A nullable production is a production that can match an empty string.
      def mark_nullable
        rules.each do |prod|
          if prod.empty?
            prod.nullable = true
          else
            # If all rhs members are all nullable, then rule is nullable
            prod.nullable = prod.rhs.members.all?(&:nullable?)
          end
        end
      end

      def add_symbol(aSymbol)
        its_name = aSymbol.name
        return if name2symbol.include? its_name

        @symbols << aSymbol
        @name2symbol[its_name] = aSymbol
      end

      # Retrieve all the production rules that share the same symbol in lhs
      def rules_for(aNonTerm)
        rules.select { |a_rule| a_rule.lhs == aNonTerm }
      end
    end # class
  end # module
end # module

# End of file
