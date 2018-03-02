# File: Lookaround.rb

########################
# TODO: make it a binary expression
########################


require_relative 'polyadic_expression' # Access the superclass

module Regex # This module is used as a namespace
  # Lookaround is a zero-width assertion just like the start and end of line
  # anchors.
  # The difference is that lookarounds will actually match characters, but only
  # return the result of the match: match or no match.
  # That is why they are called "assertions". They do not consume characters
  # from the subject, but only assert whether a match is possible or not.
  class Lookaround < PolyadicExpression
    # The "direction" of the lookaround. Can be ahead or behind. It specifies
    # the relative position of the expression to match compared to
    # the current 'position' in the subject text.
    attr_reader(:dir)

    # The kind indicates whether the assertion is positive
    # (succeeds when there is a match) or negative
    # (assertion succeeds when there is NO match).
    attr_reader(:kind)

    # Constructor.
    # [assertedExpression]  A sub-expression to match.
    # [theDir]  One of the following values: [ :ahead, :behind ]
    # [theKind] One of the following values: [ :positive, :negative ]
    def initialize(assertedExpression, theDir, theKind)
      super([assertedExpression])
      @dir = theDir
      @kind = theKind
    end

    # Conversion method re-definition.
    # Purpose: Return the String representation of the captured expression.
    def to_str()
      result = children[0].to_str
      dir_syntax = (dir == :ahead) ? '' : '<'
      kind_syntax = (kind == :positive) ? '=' : '!'
      result << '(?' + dir_syntax + kind_syntax + children[1].to_str + ')'
      return result
    end
  end # class
end # module

# End of file
