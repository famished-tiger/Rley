# frozen_string_literal: true

require_relative 'base_formatter'


module Rley # This module is used as a namespace
  # Namespace dedicated to parse tree formatters.
  module Formatter
    # A formatter class that draws parse trees by using characters
    class Asciitree < BaseFormatter
      # TODO
      attr_reader(:curr_path)

      # For each node in curr_path, there is a corresponding string value.
      # Allowed string values are: 'first', 'last', 'first_and_last', 'other'
      attr_reader(:ranks)

      # @return [String] The character pattern used for rendering 
      # a parent - child nesting
      attr_reader(:nesting_prefix)

      # @return [String] The character pattern used for a blank indentation
      attr_reader(:blank_indent)

      # @return [String] The character pattern for indentation and nesting
      # continuation.
      attr_reader(:continuation_indent)

      # Constructor.
      # @param anIO [IO] The output stream to which the parse tree
      # is written.
      def initialize(anIO)
        super(anIO)
        @curr_path = []
        @ranks = []

        @nesting_prefix = '+-- '
        @blank_indent = '    '
        @continuation_indent = '|   '
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # the children of a non-terminal node
      # @param parent [NonTerminalNode]
      # @param _children [Array<ParseTreeNode>] array of children nodes
      def before_subnodes(parent, _children)
        rank_of(parent)
        curr_path << parent
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # a non-terminal node
      # @param aNonTerm [NonTerminalNode]
      def before_non_terminal(aNonTerm)
        emit(aNonTerm)
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # a terminal node
      # @param aTerm [TerminalNode]
      def before_terminal(aTerm)
        emit(aTerm, ": '#{aTerm.token.lexeme}'")
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit of
      # the children of a non-terminal node.
      # @param _parent [NonTerminalNode]
      # @param _children [Array] array of children nodes
      def after_subnodes(_parent, _children)
        curr_path.pop
        ranks.pop
      end

      private

      # Parent node is last node in current path
      # or current path is empty (then aChild is root node)
      def rank_of(aChild)
        if curr_path.empty?
          rank = 'root'
        elsif curr_path[-1].subnodes.size == 1
          rank = 'first_and_last'
        else
          parent = curr_path[-1]
          siblings = parent.subnodes
          siblings_last_index = siblings.size - 1
          rank = case siblings.find_index(aChild)
                   when 0 then 'first'
                   when siblings_last_index then 'last'
                   else
                    'other'
                 end
        end
        ranks << rank
      end

      # 'root', 'first', 'first_and_last', 'last', 'other'
      def path_prefix()
        return '' if ranks.empty?

        prefix = +''
        @ranks.each_with_index do |rank, i|
          next if i.zero?

          case rank
            when 'first', 'other'
              prefix << continuation_indent

            when 'last', 'first_and_last', 'root'
              prefix << blank_indent
          end
        end

        prefix << nesting_prefix
        return prefix
      end

      def emit(aNode, aSuffix = '')
        output.puts("#{path_prefix}#{aNode.symbol.name}#{aSuffix}")
      end
    end # class
  end # module
end # module

# End of file
