# frozen_string_literal: true

require 'set'

require_relative 'parser'
require_relative 'ast_visitor'
require_relative '../syntax/match_closest'

module Rley # This module is used as a namespace
  # Namespace for classes that define RGN (Rley Grammar Notation)
  module RGN # This module is used as a namespace
    # Structure used by Rley to generate implicdit production rules.
    RawRule = Struct.new(:lhs, :rhs, :tag, :simple, :constraints)

    # Builder GoF pattern. Builder builds a complex object
    #   (say, a grammar) from simpler objects (terminals and productions)
    #   and using a step by step approach.
    class GrammarBuilder
      # @return [Hash{String, GrmSymbol}] The mapping of grammar symbol names
      #   to the matching grammar symbol object.
      attr_reader(:symbols)

      # @return [RGN::Parser] Parser for the right-side of productions
      attr_reader(:parser)

      # @return [Hash{ASTVisitor, Array}]
      attr_reader(:visitor2rhs)

      # @return [Array<Production>] The list of production rules for
      #   the grammar to build.
      attr_reader(:productions)

      # @return [Hash{String, String}] The synthesized raw productions
      attr_reader(:synthetized)

      # Creates a new RGN grammar builder.
      # @param aBlock [Proc] code block used to build the grammar.
      def initialize(&aBlock)
        @symbols = {}
        @productions = []
        @parser = RGN::Parser.new
        @visitor2rhs = {}
        @synthetized = {}

        if block_given?
          instance_exec(&aBlock)
          grammar_complete!
        end
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
        new_symbs = build_symbols(Syntax::Terminal, terminalSymbols)
        symbols.merge!(new_symbs)
      end

      # Add the given marker symbol to the grammar of the language
      # @param aMarkerSymbol [String] A marker symbol
      # @return [void]
      def add_marker(aMarkerSymbol)
        new_symb = build_symbol(Syntax::Marker, aMarkerSymbol)
        symbols[new_symb.name] = new_symb
      end

      # Add a production rule in the grammar given one
      # key-value pair of the form: String => String.
      #   Where the key is the name of the non-terminal appearing in the
      #   left side of the rule.
      #   The value is a sequence of grammar symbol names (optionally quantified).
      # The rule is created and inserted in the grammar.
      # @example Equivalent call syntax
      #   builder.add_production('A' => 'a  A c)
      #   builder.rule('A' => 'a A  c]) # 'rule' is a synonym
      # @param aProductionRepr [Hash{String, String}]
      #   A Hash-based representation of a production.
      # @return [Production] The created Production instance
      def add_production(aProductionRepr)
        aProductionRepr.each_pair do |(lhs_name, rhs_repr)|
          lhs = get_grm_symbol(lhs_name)
          rhs = rhs_repr.kind_of?(Array) && rhs_repr.empty? ? '' : rhs_repr.strip
          constraints = []
          if rhs.empty?
            rhs_members = []
          else
            ast = parser.parse(rhs)
            visitor = ASTVisitor.new(ast)
            visitor2rhs[visitor] = []
            visitor.subscribe(self)
            visitor.start
            root_node = ast.root
            constraints = root_node.constraints unless root_node.kind_of?(SymbolNode)

            rhs_members = visitor2rhs.delete(visitor)
          end
          new_prod = Syntax::Production.new(lhs, rhs_members)
          new_prod.constraints = constraints
          productions << new_prod
        end

        productions.last
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
            a_symb.kind_of?(Syntax::Terminal)
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

          @grammar = Syntax::Grammar.new(productions.dup)
        end

        @grammar
      end

      alias rule add_production

      # When a symbol, say symb, in a rhs is followed by a '*' modifier,
      # then a rule will be generated with a lhs named symb * suffix_plus
      # implicitly called: rule('declaration_star' => 'declaration_star declaration').tag suffix_star_more
      # implicitly called: rule('declaration_star' => '').tag suffix_star_last
      def suffix_qmark
        '_qmark'
      end

      def suffix_qmark_one
        '_qmark_one'
      end

      def suffix_qmark_none
        '_qmark_none'
      end

      # When a symbol, say symb, in a rhs is followed by a '*' modifier,
      # then a rule will be generated with a lhs named symb * suffix_plus
      # implicitly called: rule('declaration_star' => 'declaration_star declaration').tag suffix_star_more
      # implicitly called: rule('declaration_star' => '').tag suffix_star_last
      def suffix_star
        '_star'
      end

      def suffix_star_more
        '_star_more'
      end

      def suffix_star_none
        '_star_none'
      end

      # When a symbol, say symb, in a rhs is followed by a '+' modifier,
      # then a rule will be generated with a lhs named symb + suffix_plus
      # implicitly called: rule('digit_plus' => 'digit_plus digit').tag suffix_plus_more
      # implicitly called: rule('digit_plus' => 'digit').tag suffix_plus_last
      def suffix_plus
        '_plus'
      end

      def suffix_plus_more
        '_plus_more'
      end

      def suffix_plus_one
        '_plus_one'
      end

      def repetition2suffix(aRepetition)
        mapping = {
          zero_or_one: suffix_qmark,
          zero_or_more: suffix_star,
          exactly_one: '',
          one_or_more: suffix_plus
        }

        mapping[aRepetition]
      end

      def modifier2suffix(aModifier)
        mapping = {
          '?' => suffix_qmark,
          '*' => suffix_star,
          '+' => suffix_plus
        }

        mapping[aModifier]
      end

      ##################################
      # RGN's AST visit notification events
      # ################################
      def after_symbol_node(aSymbolNode, aVisitor)
        symb_name = aSymbolNode.name
        symb = get_grm_symbol(symb_name)
        visitor2rhs[aVisitor] << symb
      end

      def after_sequence_node(aSequenceNode, _visitor)
        add_constraints(aSequenceNode)
      end

      def after_repetition_node(aRepNode, aVisitor)
        add_constraints(aRepNode)
        return if aRepNode.repetition == :exactly_one

        node_name = aRepNode.name
        child_name = aRepNode.subnodes[0].name

        if aRepNode.child.is_a?(SequenceNode) &&
           !symbols.include?(child_name) && aRepNode.repetition != :zero_or_one
          add_nonterminal(child_name)
          rhs = aRepNode.child.to_text
          add_raw_rule(child_name, rhs, 'return_children', true)
        end

        case aRepNode.repetition
        when :zero_or_one
          # implicitly called: rule('node_name_qmark' => 'node_name_qmark').tag suffix_qmark_one
          # implicitly called: rule('node_name_qmark' => '').tag suffix_qmark_none
          unless symbols.include? node_name
            add_nonterminal(node_name)
            if aRepNode.child.is_a?(SequenceNode) && !aRepNode.child.constraints.empty?
              aRepNode.constraints.merge(aRepNode.child.constraints)
            end
            rhs = aRepNode.child.to_text
            add_raw_rule(node_name, rhs, 'return_children', false, aRepNode.constraints)
            add_raw_rule(node_name, [], suffix_qmark_none, true)
          end

        when :zero_or_more
          # implicitly called: rule('node_name_star' => 'node_name_star node_name').tag suffix_star_more
          # implicitly called: rule('node_name_star' => '').tag suffix_star_none
          unless symbols.include? node_name
            add_nonterminal(node_name)
            rhs = "#{node_name} #{child_name}"
            add_raw_rule(node_name, rhs, suffix_star_more)
            add_raw_rule(node_name, '', suffix_star_none)
          end

        when :one_or_more
          unless symbols.include? node_name
            add_nonterminal(node_name)
            add_raw_rule(node_name, "#{node_name} #{child_name}", suffix_plus_more)
            add_raw_rule(node_name, child_name, suffix_plus_one)
          end
        else
          raise StandardError, 'Unhandled multiplicity'
        end

        symb = get_grm_symbol(node_name)
        visitor2rhs[aVisitor] << symb
      end

      # A notification to the builderobject that the programmer
      # has completed the entry of terminals and production rules
      def grammar_complete!
        process_raw_rules
      end

      private

      def add_nonterminal(aName)
        symbols[aName] = Syntax::NonTerminal.new(aName)
      end

      def simple_rule(aProductionRepr)
        aProductionRepr.each_pair do |(lhs_name, rhs_repr)|
          lhs = get_grm_symbol(lhs_name)

          if rhs_repr.kind_of?(String)
            rhs = rhs_repr.strip.scan(/\S+/)
          else
            rhs = rhs_repr
          end

          members = rhs.map do |name|
            if name.end_with?('?', '*', '+')
              modifier = name[-1]
              suffix = modifier2suffix(modifier)
              get_grm_symbol("#{name.chop}#{suffix}")
            else
              get_grm_symbol(name)
            end
          end
          new_prod = Syntax::Production.new(lhs, members)
          productions << new_prod
        end

        productions.last
      end

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

        symbs
      end

      # If the argument is already a grammar symbol object then it is
      # returned as is. Otherwise, the argument is treated as a name
      # for a new instance of the given class.
      # @param aClass [Class] The class of grammar symbols to instantiate
      # @param aSymbolArg [GrmSymbol-like or String]
      # @return [Array] list of grammar symbols
      def build_symbol(aClass, aSymbolArg)
        if aSymbolArg.kind_of?(Syntax::GrmSymbol)
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

        symbols[name] = Syntax::NonTerminal.new(name) unless symbols.include? name

        symbols[name]
      end

      def add_constraints(aCompositeNode)
        aCompositeNode.subnodes.each_with_index do |sn, i|
          next if sn.annotation.empty?

          matching = sn.annotation['match_closest']
          constraint = Syntax::MatchClosest.new(aCompositeNode, i, matching)
          aCompositeNode.constraints << constraint
        end
      end

      # def sequence_name(aSequenceNode)
      #   subnode_names = +''
      #   aSequenceNode.subnodes.each do |subn|
      #     case subn
      #     when SymbolNode
      #       subnode_names << "_#{subn.name}"
      #     when SequenceNode
      #       subnode_names << "_#{sequence_name(subn)}"
      #     when RepetitionNode
      #       suffix = repetition2suffix(subn.repetition)
      #       subnode_names << suffix
      #     end
      #   end
      #
      #   "seq#{subnode_names}"
      # end

      def node_base_name(aNode)
        if aNode.kind_of?(SymbolNode)
          aNode.name
        else
          sequence_name(aNode)
        end
      end

      def node_decorated_name(aNode)
        base_name = node_base_name(aNode)
        suffix = repetition2suffix(aNode.repetition)

        "#{base_name}#{suffix}"
      end

      # def serialize_sequence(aSequenceNode)
      #   text = +''
      #   aSequenceNode.subnodes.each do |sn|
      #     text << ' '
      #     case sn
      #     when SymbolNode
      #       text << sn.name
      #     when SequenceNode
      #       text << sequence_name(sn)
      #     when RepetitionNode
      #       suffix = repetition2suffix(sn.repetition)
      #       text << suffix
      #     end
      #   end
      #
      #   text.strip
      # end

      def add_raw_rule(aSymbol, aRHS, aTag, simplified = false, constraints = [])
        raw_rule = RawRule.new(aSymbol, aRHS, aTag, simplified, constraints)
        if synthetized.include?(aSymbol)
          @synthetized[aSymbol] << raw_rule
        else
          @synthetized[aSymbol] = [raw_rule]
        end
      end

      def process_raw_rules
        until synthetized.empty?
          raw_rules = synthetized.delete(synthetized.keys.first)
          raw_rules.each do |raw|
            new_prod = nil
            if raw.simple
              new_prod = simple_rule(raw.lhs => raw.rhs)
            else
              new_prod = rule(raw.lhs => raw.rhs)
            end
            new_prod.tag(raw.tag)
            new_prod.constraints.concat(raw.constraints)
          end
        end
      end
    end # class
  end # module
end # module

# End of file
