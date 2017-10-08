require_relative '../syntax/terminal'
require_relative '../syntax/non_terminal'
require_relative '../gfg/end_vertex'
require_relative '../gfg/item_vertex'
require_relative '../gfg/start_vertex'
require_relative 'parse_tree_builder'
require_relative '../ptree/non_terminal_node'
require_relative '../ptree/terminal_node'
require_relative '../ptree/parse_tree'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # The purpose of a CSTBuilder is to build piece by piece a CST
    # (Concrete Syntax Tree) from a sequence of input tokens and
    # visit events produced by walking over a GFGParsing object.
    # Uses the Builder GoF pattern.
    # The Builder pattern creates a complex object
    # (say, a parse tree) from simpler objects (terminal and non-terminal
    # nodes) and using a step by step approach.
    class CSTBuilder < ParseTreeBuilder

      protected
      
      # Method to override
      # Create a parse tree object with given
      # node as root node.
      def create_tree(aRootNode)
        return Rley::PTree::ParseTree.new(aRootNode)
      end      

      # Method to override
      # Factory method for creating a node object for the given
      # input token.
      # @param _terminal [Terminal] Terminal symbol associated with the token
      # @param aTokenPosition [Integer] Position of token in the input stream
      # @param aToken [Token] The input token
      def new_leaf_node(_production, _terminal, aTokenPosition, aToken)
        PTree::TerminalNode.new(aToken, aTokenPosition)
      end

      # Method to override.
      # Factory method for creating a parent node object.
      # @param aProduction [Production] Production rule
      # @param aRange [Range] Range of tokens matched by the rule
      # @param theTokens [Array] The input tokens
      # @param theChildren [Array] Children nodes (one per rhs symbol)
      def new_parent_node(aProduction, aRange, theTokens, theChildren)
        node = Rley::PTree::NonTerminalNode.new(aProduction.lhs, aRange)
        theChildren.reverse_each { |child| node.add_subnode(child) }
        return node
      end
    end # class
  end # module
end # module

# End of file
