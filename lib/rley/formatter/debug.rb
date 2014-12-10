require_relative 'base_formatter'


module Rley # This module is used as a namespace
  # Namespace dedicated to parse tree formatters.
  module Formatter

    # A formatter class that renders the visit notification events
    # from a parse tree visitor
    # @example
    #   some_grammar = ... # Points to a DynamicGrammar-like object
    #   # Output the result to the standard console output
    #   formatter = Sequitur::Formatter::Debug.new(STDOUT)
    #   # Render the visit notifications
    #   formatter.run(some_grammar.visitor)
    class Debug < BaseFormatter
      # Current indentation level
      attr(:indentation)

      # Constructor.
      # @param anIO [IO] The output stream to which the rendered grammar
      # is written.
      def initialize(anIO)
        super(anIO)
        @indentation = 0
      end

      public

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit the given
      # parse tree
      # @param _ptree [ParseTree]
      def before_ptree(_ptree)
        output_event(__method__, indentation)
        indent
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # a non-terminal node
      # @param _nonterm [NonTerminalNode]
      def before_non_terminal(_nonterm)
        output_event(__method__, indentation)
        indent
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # the children of a non-terminal node
      # @param _parent [NonTerminalNode]
      # @param _children [Array] array of children nodes
      def before_children(_parent, _children)
        output_event(__method__, indentation)
        indent
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # a terminal node
      # @param _term [TerminalNode]
      def before_terminal(_term)
        output_event(__method__, indentation)
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit of
      # a terminal node.
      # @param _term [TerminalNode]
      def after_terminal(_term)
        output_event(__method__, indentation)
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit of
      # a non-terminal node
      # @param _nonterm [NonTerminalNode]
      def after_non_terminal(_)
        dedent
        output_event(__method__, indentation)
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit of
      # the children of a non-terminal node.
      # @param _parent [NonTerminalNode]
      # @param _children [Array] array of children nodes
      def after_children(_parent, _children)
        dedent
        output_event(__method__, indentation)
      end


      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit
      # of the given parse tree
      # @param _ptree [ParseTree]
      def after_ptree(_ptree)
        dedent
        output_event(__method__, indentation)
      end

      private

      def indent()
        @indentation += 1
      end

      def dedent()
        @indentation -= 1
      end

      def output_event(anEvent, indentationLevel)
        output.puts "#{' ' * 2 * indentationLevel}#{anEvent}"
      end

    end # class
  end # module
end # module

# End of file
