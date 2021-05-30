# frozen_string_literal: true

require_relative '../ptree/parse_tree'
require_relative 'parse_tree_builder'

module Rley # This module is used as a namespace
  module ParseRep # This module is used as a namespace
    # Abstract class (to be subclassed).
    # The purpose of an ASTBaseBuilder is to build piece by piece an AST
    # (Abstract Syntax Tree) from a sequence of input tokens and
    # visit events produced by walking over a GFGParsing object.
    # It is an implementation of the Builder GoF pattern.
    # The Builder pattern creates a complex object
    # (say, a parse tree) from simpler objects (terminal and non-terminal
    # nodes) and using a step by step approach.
    class ASTBaseBuilder < ParseTreeBuilder
      # Method to override in subclass.
      # Returns a Hash
      # @return [Hash{String => Class}, Hash{String => Hash{String => Class}}]
      #   Returned hash contains pairs of the form:
      #   terminal name => Class implementing the terminal tokens
      #   terminal name => Hash with pairs: production name => Class
      def terminal2node
        raise NotImplementedError
      end

      # Method to override in subclass.
      # Default class for representing terminal nodes.
      # @return [Class]
      def terminalnode_class
        PTree::TerminalNode
      end

      # Default method name to invoke when production
      # with given name is invoked.
      # Override this method for other method naming convention.
      # @param aProductionName [String]
      # @return [String]
      def method_name(aProductionName)
        "reduce_#{aProductionName}"
      end

      # Utility method.
      # Simply return the first child node
      # @param _range [Lexical::TokenRange]
      # @param _tokens [Array<Lexical::Token>]
      # @param theChildren [Array<Object>]
      def return_first_child(_range, _tokens, theChildren)
        theChildren[0]
      end

      # Utility method.
      # Simply return the second child node
      # @param _range [Lexical::TokenRange]
      # @param _tokens [Array<Lexical::Token>]
      # @param theChildren [Array<Object>]
      def return_second_child(_range, _tokens, theChildren)
        theChildren[1]
      end

      # Utility method.
      # Simply return the last child node
      # @param _range [Lexical::TokenRange]
      # @param _tokens [Array<Lexical::Token>]
      # @param theChildren [Array<Object>]
      def return_last_child(_range, _tokens, theChildren)
        theChildren[-1]
      end

      # Simply return an epsilon symbol
      # @param _range [Lexical::TokenRange]
      # @param _tokens [Array<Lexical::Token>]
      # @param _children [Array<Object>]
      def return_epsilon(_range, _tokens, _children)
        nil
      end

      protected

      # Overriding method.
      # Create a parse tree object with given
      # node as root node.
      def create_tree(aRootNode)
        Rley::PTree::ParseTree.new(aRootNode)
      end

      # Factory method for creating a node object for the given
      # input token.
      # @param aProduction [Syntax::Production] Relevant production rule
      # @param aTerminal [Syntax::Terminal] Terminal associated with the token
      # @param aTokenPosition [Integer] Position of token in the input stream
      # @param aToken [Lexical::Token] The input token
      def new_leaf_node(aProduction, aTerminal, aTokenPosition, aToken)
        klass = terminal2node.fetch(aTerminal.name, terminalnode_class)
        if klass.is_a?(Hash)
          # Lexical ambiguity...
          klass = klass.fetch(aProduction.name)
        end
        klass.new(aToken, aTokenPosition)
      end

      # Method to override.
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
                    msg = "Don't know production '#{aProduction.name}'"
                    raise StandardError, msg
                 end
        end
        return node
      end
    end # class
  end # module
end # module
# End of file
