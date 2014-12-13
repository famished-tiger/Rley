require_relative 'base_formatter'


module Rley # This module is used as a namespace
  # Namespace dedicated to parse tree formatters.
  module Formatter

    # A formatter class that renders a parse tree in JSON format
    class Json < BaseFormatter
      # Current indentation level
      attr(:indentation)

      # Array of booleans (one per indentation level).
      # Set to true after first child was visited.
      attr(:sibling_flags)

      # Constructor.
      # @param anIO [IO] The output stream to which the rendered grammar
      # is written.
      def initialize(anIO)
        super(anIO)
        @indentation = 0
        @sibling_flags = [ false ]
      end

      public

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit the given
      # parse tree
      # @param _ptree [ParseTree]
      def before_ptree(_ptree)
        print_text('', "{\n")
        indent
        print_text('', "\"root\":")
        indent
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # a non-terminal node
      # @param _nonterm [NonTerminalNode]
      def before_non_terminal(nonterm_node)
        separator = sibling_flags[-1] ? ",\n" : "\n"
        name = nonterm_node.symbol.name
        print_text(separator, "{ \"#{name}\": ")
        sibling_flags[-1] = true
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # the children of a non-terminal node
      # @param _parent [NonTerminalNode]
      # @param _children [Array] array of children nodes
      def before_children(_parent, _children)
        print_text('[', nil)
        indent
        sibling_flags.push(false)
      end

      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor is about to visit
      # a terminal node
      # @param _term [TerminalNode]
      def before_terminal(term_node)
        separator = sibling_flags[-1] ? ",\n" : "\n"
        name = term_node.symbol.name
        lexeme = term_node.token.lexeme
        print_text(separator, "{\"#{name}\": \"#{lexeme}\"}")
        sibling_flags[-1] = true
      end


      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit of
      # the children of a non-terminal node.
      # @param _parent [NonTerminalNode]
      # @param _children [Array] array of children nodes
      def after_children(_parent, _children)
        sibling_flags.pop
        print_text("\n", ']')
        dedent
        print_text("\n", '}')
      end


      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit of
      # a non-terminal node
      # @param _nonterm [NonTerminalNode]
      def after_non_terminal(_)
      end


      # Method called by a ParseTreeVisitor to which the formatter subscribed.
      # Notification of a visit event: the visitor completed the visit
      # of the given parse tree
      # @param _ptree [ParseTree]
      def after_ptree(_ptree)
        dedent
        #print_text("\n", ']')
        dedent
        print_text("\n", '}')
      end

      private

      def indent()
        @indentation += 1
      end

      def dedent()
        @indentation -= 1
      end

      def print_text(aSeparator, aText)
        output.print aSeparator
        output.print "#{' ' * 2 * @indentation}#{aText}" unless aText.nil?
      end

    end # class
  end # module
end # module

# End of file
