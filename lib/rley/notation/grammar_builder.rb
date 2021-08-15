# frozen_string_literal: true

require 'set'
require_relative 'parser'
require_relative 'ast_visitor'
require_relative '../syntax/match_closest'

module Rley # This module is used as a namespace
  module Notation # This module is used as a namespace
    # Builder GoF pattern. Builder builds a complex object
    #   (say, a grammar) from simpler objects (terminals and productions)
    #   and using a step by step approach.
    class GrammarBuilder
      # @return [Hash{String, GrmSymbol}] The mapping of grammar symbol names
      #   to the matching grammar symbol object.
      attr_reader(:symbols)

      # @return [Notation::Parser] Parser for the right-side of productions
      attr_reader(:parser)

      # @return [Hash{ASTVisitor, Array}]
      attr_reader(:visitor2rhs)

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
        @parser = Notation::Parser.new
        @visitor2rhs = {}

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
        new_symbs = build_symbols(Syntax::Terminal, terminalSymbols)
        symbols.merge!(new_symbs)
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
      # AST visit notification events
      # ################################
      def after_symbol_node(aSymbolNode, aVisitor)
        symb_name = aSymbolNode.name

        case aSymbolNode.repetition
        when :zero_or_one
          # implicitly called: rule('symb_name_qmark' => 'symb_name_qmark').tag suffix_qmark_one
          # implicitly called: rule('symb_name_qmark' => '').tag suffix_qmark_none
          name_modified = "#{symb_name}#{suffix_qmark}"
          unless symbols.include? name_modified
            symbols[name_modified] = Syntax::NonTerminal.new(name_modified)
            rule(name_modified => "#{symb_name}" ).tag suffix_qmark_one
            rule(name_modified => '').tag suffix_qmark_none
          end
          symb_name = name_modified

        when :zero_or_more
          # implicitly called: rule('symb_name_star' => 'symb_name_star symb_name').tag suffix_star_more
          # implicitly called: rule('symb_name_star' => '').tag suffix_star_none
          name_modified = "#{symb_name}#{suffix_star}"
          unless symbols.include? name_modified
            symbols[name_modified] = Syntax::NonTerminal.new(name_modified)
            rule(name_modified => "#{name_modified} #{symb_name}").tag suffix_star_more
            rule(name_modified => '').tag suffix_star_none
          end
          symb_name = name_modified

        when :exactly_one
          # Do nothing

        when  :one_or_more
          name_modified = "#{symb_name}#{suffix_plus}"
          unless symbols.include? name_modified
            symbols[name_modified] = Syntax::NonTerminal.new(name_modified)
            rule(name_modified => "#{name_modified} #{symb_name}").tag suffix_plus_more
            rule(name_modified => symb_name).tag suffix_plus_one
          end
          symb_name = name_modified
        else
          raise StandardError, 'Unhandled multiplicity'
        end

        symb = get_grm_symbol(symb_name)
        visitor2rhs[aVisitor] << symb
      end

      def after_sequence_node(aSequenceNode, _visitor)
        aSequenceNode.subnodes.each_with_index do |sn, i|
          next if sn.annotation.empty?
          matching = sn.annotation['match_closest']
          aSequenceNode.constraints << Syntax::MatchClosest.new(aSequenceNode, i, matching)
        end
      end

      def after_grouping_node(aGroupingNode, aVisitor)
        after_sequence_node(aGroupingNode, aVisitor)
        symb_name = sequence_name(aGroupingNode)

        unless symbols.include?(symb_name) || aGroupingNode.repetition == :exactly_one
          symbols[symb_name] = Syntax::NonTerminal.new(symb_name)
          simple_rule(symb_name => serialize_sequence(aGroupingNode) ).tag 'return_children'
          prod = productions.last
          prod.constraints = aGroupingNode.constraints
        end
        name_modified = "#{symb_name}#{repetition2suffix(aGroupingNode.repetition)}"

        case aGroupingNode.repetition
        when :zero_or_one
          # implicitly called: rule('symb_name_qmark' => 'symb_name_qmark').tag suffix_qmark_one
          # implicitly called: rule('symb_name_qmark' => '').tag suffix_qmark_none
          unless symbols.include? name_modified
            symbols[name_modified] = Syntax::NonTerminal.new(name_modified)
            simple_rule(name_modified => symb_name).tag suffix_qmark_one
            simple_rule(name_modified => []).tag suffix_qmark_none
          end

        when :zero_or_more
          # implicitly called: rule('symb_name_star' => 'symb_name_star symb_name').tag suffix_star_more
          # implicitly called: rule('symb_name_star' => '').tag suffix_star_none
          unless symbols.include? name_modified
            symbols[name_modified] = Syntax::NonTerminal.new(name_modified)
            rule(name_modified => "#{name_modified} #{symb_name}").tag suffix_star_more
            rule(name_modified => '').tag suffix_star_none
          end

        when :exactly_one
          # Do nothing

        when :one_or_more
          unless symbols.include? name_modified
            symbols[name_modified] = Syntax::NonTerminal.new(name_modified)
            rule(name_modified => "#{name_modified} #{symb_name}").tag suffix_plus_more
            rule(name_modified => symb_name).tag suffix_plus_one
          end
        else
          raise StandardError, 'Unhandled multiplicity'
        end

        unless aGroupingNode.repetition == :exactly_one
          symb = get_grm_symbol(name_modified)
          visitor2rhs[aVisitor] << symb
        end
      end

      private

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
              suffix = modifier2suffix(aModifier)
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

      def sequence_name(aSequenceNode)
        subnode_names = +''
        aSequenceNode.subnodes.each do |subn|
          case subn
          when SymbolNode
            subnode_names << "_#{subn.name}"
          when SequenceNode
            subnode_names << "_#{sequence_name(subn)}"
          end
          suffix = repetition2suffix(subn.repetition)
          subnode_names << suffix
        end

        "seq#{subnode_names}"
      end

      def node_base_name(aNode)
        if aNode.kind_of?(SymbolNode)
          aNode.name
        else
          sequence_name(aNode)
        end
      end

      def node_decorated_name(aNdoe)
        base_name = node_base_name(aNode)
        suffix = repetition2suffix(aNode.repetition)

        "#{base_name}#{suffix}"
      end

      def serialize_sequence(aSequenceNode)
        text = +''
        aSequenceNode.subnodes.each do |sn|
          text << ' '
          case sn
          when SymbolNode
            text << sn.name
          when SequenceNode
            text << sequence_name(sn)
          end

          suffix = suffix = repetition2suffix(sn.repetition)
          text << suffix
        end

        text.strip
      end
    end # class
  end # module
end # module

# End of file
