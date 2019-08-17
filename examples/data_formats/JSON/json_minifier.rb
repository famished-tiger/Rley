# frozen_string_literal: true

# File: json_minifier.rb


# A JSON minifier, it removes unnecessary whitespaces in a JSON expression.
# It typically reduces size by half.
class JSONMinifier
  # The IO output stream in which the formatter's result will be sent.
  attr_reader(:output)

  # Constructor.
  # @param anIO [IO] an output IO where the formatter's result will
  # be placed.
  def initialize(anIO)
    @output = anIO
  end

  # Given a parse tree visitor, perform the visit
  # and render the visit events in the output stream.
  # @param aVisitor [ParseTreeVisitor]
  def render(aVisitor)
    aVisitor.subscribe(self)
    aVisitor.start
    aVisitor.unsubscribe(self)
  end

  # Method called by a ParseTreeVisitor to which the formatter subscribed.
  # Notification of a visit event: the visitor is about to visit
  # a terminal node. The only thing the JSON minifier has to do is
  # to render the input tokens almost as they appear initially.
  # @param aTerm [TerminalNode]
  def before_terminal(aTerm)
    # Lexeme is the original text representation of the token
    lexeme = aTerm.token.lexeme
    literal = if aTerm.symbol.name == 'string'
                # String values are delimited by double quotes
                '"' + lexeme + '"'
              else
                lexeme
              end

    output << literal
  end
end # class

# End of file
