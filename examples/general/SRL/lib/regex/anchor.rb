# File: anchor.rb

require_relative "atomic_expression"	# Access the superclass

module Regex # This module is used as a namespace
  # An anchor is a zero-width assertion based on the current position.
  class Anchor < AtomicExpression
    # A Hash for converting a lexeme to a symbolic value
    AnchorToSymbol = {
      # Lexeme => Symbol value
      '^' => :soLine,	# Start of line
      '$' => :eoLine,	# End of line
      '\A' => :soSubject,
      '\b' => :wordBoundary,
      '\B' => :nonAtWordBoundary,
      '\G' => :firstMatch,
      '\z' => :eoSubject,
      '\Z' => :eoSubjectOrBeforeNLAtEnd
    }

    # A symbolic value that identifies the type of assertion to perform
    attr_reader(:kind)

    # Constructor
    # @param aKind [String] Lexeme representation of the anchor
    def initialize(aKind)
      @kind = valid_kind(aKind)
    end

    public

    # Conversion method re-definition.
    # Purpose: Return the String representation of the expression.
    def to_str()
      return AnchorToSymbol.rassoc(kind).first()
    end

    private

    # Return the symbolic value corresponding to the given lexeme.
    def valid_kind(aKind)
      return AnchorToSymbol[aKind]
    end

  end # class
end # module

# End of file