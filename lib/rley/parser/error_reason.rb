module Rley # Module used as a namespace
  module Parser # This module is used as a namespace
    # Abstract class. An instance represents an explanation describing
    # the likely cause of a parse error
    # detected by Rley.
    class ErrorReason
      # @!attribute [r] rank
      #   @return [Fixnum] The rank number of the offending input token
      attr_reader(:rank)

      # Constructor
      # @param aRank [Fixnum] The sequence number of the offending input token.
      def initialize(aRank)
        @rank = aRank
      end

      # @return [String] the result of invoking reason.to_s
      def message()
        return to_s
      end

      # @return [String] Return this reason's class name and message
      def inspect
        "#{self.class.name}: #{message}"
      end
    end # class


    # This parse error occurs when no input for parsing was provided
    # while the grammar requires some non-empty input.
    class NoInput < ErrorReason
      def initialize()
        super(0)
      end

      # Returns the reason's message.
      def to_s
        'Input cannot be empty.'
      end
    end # class

    # Abstract class and subclass of ErrorReason.
    # This specialization represents errors in which the input
    # didn't match one of the expected token.
    class ExpectationNotMet < ErrorReason
      # The last input token read when error was detected
      attr_reader(:last_token)

      # The terminal symbols expected when error was occurred
      attr_reader(:expected_terminals)

      def initialize(aRank, lastToken, expectedTerminals)
        super(aRank)
        raise StandardError, 'Internal error: nil token' if lastToken.nil?

        @last_token = lastToken.dup
        @expected_terminals = expectedTerminals.dup
      end

      protected

      def position()
        return last_token.position if last_token.respond_to?(:position)

        rank + 1
      end

      # Emit a text explaining the expected terminal symbols
      def expectations
        term_names = expected_terminals.map(&:name)
        explain = 'Expected one '
        explain << if expected_terminals.size > 1
                     "of: ['#{term_names.join("', '")}']"
                   else
                     "'#{term_names[0]}'"
                   end
        return explain
      end
    end # class

    # This parse error occurs when the current token from the input
    # is unexpected according to the grammar rules.
    class UnexpectedToken < ExpectationNotMet
      # Returns the reason's message.
      def to_s
        err_msg = "Syntax error at or near token #{position} "
        err_msg << ">>>#{last_token.lexeme}<<<\n"
        err_msg << expectations
        err_msg << ", found a '#{last_token.terminal}' instead."

        return err_msg
      end
    end # class

    # This parse error occurs when all input tokens were consumed
    # but the parser still expected one or more tokens from the input.
    class PrematureInputEnd < ExpectationNotMet
      # Returns the reason's message.
      def to_s
        err_msg = "Premature end of input after '#{last_token.lexeme}'"
        err_msg << " at position #{position}\n"
        err_msg << "#{expectations}."

        return err_msg
      end
    end # class
  end # module
end # module

# End of file
