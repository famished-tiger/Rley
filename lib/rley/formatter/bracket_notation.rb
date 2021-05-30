# frozen_string_literal: true

require_relative 'base_formatter'


module Rley # This module is used as a namespace
  # Namespace dedicated to parse tree formatters.
  module Formatter
    # A formatter class that generates the labelled bracket notation (LBN)
    # representation of a parse tree.
    # The output can be then fed to an application or library that is
    # capable of displaying parse tree diagrams.
    # For Ruby developers, there is RSyntaxTree by Yoichiro Hasebe.
    # (accessible via: http://yohasebe.com/rsyntaxtree/)
    class BracketNotation < BaseFormatter
      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # a non-terminal node
      # @param aNonTerm [NonTerminalNode]
      def before_non_terminal(aNonTerm)
        write("[#{aNonTerm.symbol.name} ")
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # a terminal node
      # @param aTerm [TerminalNode]
      def before_terminal(aTerm)
        write("[#{aTerm.symbol.name} ")
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit of
      # a terminal node.
      # @param aTerm [TerminalNode]
      def after_terminal(aTerm)
        # Escape all opening and closing square brackets
        escape_lbrackets = aTerm.token.lexeme.gsub(/\[/, '\[')
        escaped = escape_lbrackets.gsub(/\]/, '\]')
        write("#{escaped}]")
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit of
      # a non-terminal node
      # @param _nonterm [NonTerminalNode]
      def after_non_terminal(_nonterm)
        write(']')
      end

      private

      def write(aText)
        output.write(aText)
      end
    end # class
  end # module
end # module

# End of file
