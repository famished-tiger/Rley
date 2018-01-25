# File: char_shorthand.rb

require_relative "atomic_expression"	# Access the superclass

module Regex # This module is used as a namespace

  # A pre-defined character class is in essence a name for a built-in, standard character class.
  class CharShorthand < AtomicExpression
    # A constant Hash that defines all the predefined character shorthands.
    # It contains pairs of the form:
    # a pre-defined character shorthand letter => a CharRange object
    StandardCClasses = {
      'd' => '[0-9]',
      'D' => '[^0-9]',
      'h' => '[0-9a-fA-F]',
      'H' => '[^0-9a-fA-F]',
      's' => '[ \t\r\n\f]',
      'S' => '[^ \t\r\n\f]',
      'w' => '[0-9a-zA-Z_]',
      'W' => '[^0-9a-zA-Z_]'
    }

    # An one-letter abbreviation
    attr_reader(:shortname)

    # Constructor
    def initialize(aShortname)
      @shortname = valid_shortname(aShortname)
    end

  public
    # Conversion method re-definition.
    # Purpose: Return the String representation of the expression.
    def to_str()
      return "\\#{shortname}"
    end

  private
    # Return the validated short name.
    def valid_shortname(aShortname)
      raise StandardError, "Unknown predefined character class \\#{aShortname}" unless StandardCClasses.include? aShortname

      return aShortname
    end

  end # class

end # module

# End of file