module Rley # This module is used as a namespace

  # Namespace dedicated to parse tree formatters.
  module Formatter
    # Superclass for parse tree formatters.
    class BaseFormatter
      # The IO output stream in which the formatter's result will be sent.
      attr_reader(:output)

      # Constructor.
      # @param anIO [IO] an output IO where the formatter's result will
      # be placed.
      def initialize(anIO)
        @output = anIO
      end

      public

      # Given a parse tree visitor, perform the visit
      # and render the visit events in the output stream.
      # @param aVisitor [ParseTreeVisitor]
      def render(aVisitor)
        aVisitor.subscribe(self)
        aVisitor.start
        aVisitor.unsubscribe(self)
      end
    end # class
  end # module
end # module

# End of file
