# frozen_string_literal: true

require_relative '../parse_rep/ast_base_builder'
require_relative '../engine'
require_relative 'all_notation_nodes'

module Rley
  module RGN
    # The purpose of ASTBuilder is to build piece by piece an AST
    # (Abstract Syntax Tree) from a sequence of input tokens and
    # visit events produced by walking over a GFGParsing object.
    class ASTBuilder < Rley::ParseRep::ASTBaseBuilder
      unless defined?(Name2special)
        # Mapping Token name => operator | separator | delimiter characters
        # @return [Hash{String => String}]
        Name2special = {
          'COMMA' =>  ',',
          'ELLIPSIS' => '..',
          'LEFT_BRACE' =>  '{',
          'LEFT_PAREN' => '(',
          'PLUS' => '+',
          'QUESTION_MARK' => '?',
          'RIGHT_BRACE' => '}',
          'RIGHT_PAREN' => ')',
          'STAR' => '*'
        }.freeze
      end

      protected

      def terminal2node
        Terminal2NodeClass # steep:ignore UnknownConstant
      end

      # Method override
      def new_leaf_node(_production, _terminal, aTokenPosition, aToken)
        Rley::PTree::TerminalNode.new(aToken, aTokenPosition)
      end

      # Factory method for creating a parent node object.
      # @param aProduction [Production] Production rule
      # @param aRange [Range] Range of tokens matched by the rule
      # @param theTokens [Array] The input tokens
      # @param theChildren [Array] Children nodes (one per rhs symbol)
      def new_parent_node(aProduction, aRange, theTokens, theChildren)
        mth_name = method_name(aProduction.name)
        if respond_to?(mth_name, true)
          node = send(mth_name, aProduction, aRange, theTokens, theChildren)
        else
          # Default action...
          node = case aProduction.rhs.size
                 when 0
                   return_epsilon(aRange, theTokens, theChildren)
                 when 1
                   return_first_child(aRange, theTokens, theChildren)
                 else
                   node = Rley::PTree::NonTerminalNode.new(aProduction.lhs, aRange)
                   theChildren&.reverse_each do |child|
                     node.add_subnode(child) if child
                   end

                   node
                 end
        end

        node
      end

      # Return the AST node corresponding to the second symbol in the rhs
      def reduce_to_2nd_symbol(_production, _range, _tokens, theChildren)
        theChildren[1]
      end

      #####################################
      #  RGN SEMANTIC ACTIONS
      #####################################

      # rule('rhs' => 'member_seq').tag 'sequence'
      def reduce_sequence(_production, _range, _tokens, theChildren)
        if theChildren[0].size == 1
          theChildren[0].first
        else
          SequenceNode.new(theChildren[0])
        end
      end

      # rule('member_seq' => 'member_seq member').tag 'more_members'
      def reduce_more_members(_production, _range, _tokens, theChildren)
        theChildren[0] << theChildren[1]
      end

      # rule('member_seq' => 'member')
      def reduce_one_member(_production, _range, _tokens, theChildren)
        [theChildren[0]]
      end

      # rule('strait_member' => 'base_member annotation')
      def reduce_annotated_member(_production, _range, _tokens, theChildren)
        if theChildren[1].include?('repeat')
          node = RepetitionNode.new(theChildren[0], theChildren[1].fetch('repeat'))
          theChildren[1].delete('repeat')
          theChildren[0].annotation = theChildren[1]
          node
        else
          theChildren[0].annotation = theChildren[1]
          theChildren[0]
        end
      end

      # rule('base_member' => 'SYMBOL')
      def reduce_symbol(_production, _range, _tokens, theChildren)
        SymbolNode.new(theChildren[0].token.position, theChildren[0].token.lexeme)
      end

      # rule('base_member' => 'LEFT_PAREN member_seq RIGHT_PAREN')
      def reduce_grouping(_production, _range, _tokens, theChildren)
        if theChildren[1].size == 1
          theChildren[1].first
        else
          SequenceNode.new(theChildren[1])
        end
      end

      # rule('quantified_member' => 'base_member quantifier')
      def reduce_quantified_member(_production, _range, _tokens, theChildren)
        if theChildren == :exactly_one
          theChildren[0]
        else
          RGN::RepetitionNode.new(theChildren[0], theChildren[1])
        end
      end

      # rule('quantifier' => 'QUESTION_MARK')
      def reduce_question_mark(_production, _range, _tokens, _theChildren)
        :zero_or_one
      end

      # rule('quantifier' => 'STAR')
      def reduce_star(_production, _range, _tokens, _theChildren)
        :zero_or_more
      end

      # rule('quantifier' => 'PLUS')
      def reduce_plus(_production, _range, _tokens, _theChildren)
        :one_or_more
      end

      # rule('annotation' => 'LEFT_BRACE mapping RIGHT_BRACE').tag ''
      def reduce_annotation(_production, _range, _tokens, theChildren)
        theChildren[1]
      end

      # rule('mapping' => 'mapping COMMA key_value')
      def reduce_more_pairs(_production, _range, _tokens, theChildren)
        hsh = theChildren[0]
        hsh[theChildren[2].first] = theChildren[2].last

        hsh
      end

      # rule('mapping' => 'key_value').tag 'one_pair'
      def reduce_one_pair(_production, _range, _tokens, theChildren)
        { theChildren[0].first => theChildren[0].last }
      end

      # rule('key_value' => 'KEY value')
      def reduce_raw_pair(_production, _range, _tokens, theChildren)
        key = theChildren[0].token.lexeme
        value = if theChildren[1].is_a?(Rley::PTree::TerminalNode)
                  theChildren[1].token.lexeme
                else
                  theChildren[1]
                end
        [key, value]
      end

      # rule('range' => 'INT_LIT ELLIPSIS INT_LIT')
      def reduce_bound_range(_production, _range, _tokens, theChildren)
        low = theChildren[0].token.lexeme
        high = theChildren[2].token.lexeme
        case [low, high]
          when %w[0 1]
            :zero_or_one
          when %w[1 1]
            :exactly_one
          else
            Range.new(low.to_i, high.to_i)
        end
      end
    end # class
  end # module
end # module
