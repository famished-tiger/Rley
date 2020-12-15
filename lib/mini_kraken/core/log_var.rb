# frozen_string_literal: true

require_relative 'entry'

module MiniKraken
  module Core
    # Representation of a MiniKraken logical variable.
    # It is a named slot that can be associated with one value at the time.
    # In relational programming, there is no explicit assignment expression.
    # A logical variable acquires a value through an algorithm called
    # 'unification'.
    class LogVar
      include Entry # Add expected behaviour for symbol table entries

      # Create a logical variable with given name
      # @param aName [String] The name of the variable
      def initialize(aName)
        init_name(aName)
      end
    end # class
  end # module
end # module
