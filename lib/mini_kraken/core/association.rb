# frozen_string_literal: true

module MiniKraken
  module Core
    # A record that a given variable is associated with a value.
    class Association
      # @return [String] internal name of variable being associated the value.
      attr_accessor :i_name

      # @return [Term] the MiniKraken value associated with the variable
      attr_reader :value

      # @param aVariable [Variable, String] A variable or its internal name.
      # @param aValue [Term] value being associated to the variable.
      def initialize(aVariable, aValue)
        a_name = aVariable.respond_to?(:i_name) ? aVariable.i_name : aVariable
        @i_name = validated_name(a_name)
        @value = aValue
        @dependencies = nil
      end

      # Is the associated value floating, that is, it does contain
      # a variable that is either unbound or floating?
      # @param ctx [Core::Context]
      # @return [Boolean]
      def floating?(ctx)
        value.floating?(ctx)
      end

      # Is the associated value pinned, that is, doesn't contain
      # an unbound or floating variable?
      # @param ctx [Core::Context]
      # @return [Boolean]
      def pinned?(ctx)
        @pinned ||= value.pinned?(ctx)
        @pinned
      end

      # @return [Array<String>] The i_names of direct dependent variables
      def dependencies(ctx)
        @dependencies ||= value.dependencies(ctx)
        raise StandardError unless @dependencies.kind_of?(Set) || @dependencies.kind_of?(NilClass)
        @dependencies
      end

      private

      def validated_name(aName)
        raise StandardError, 'Name cannot be nil' if aName.nil?

        cleaned = aName.strip
        raise StandardError, 'Name cannot be empty or consists of spaces' if cleaned.empty?

        cleaned
      end
    end # class
  end # module
end # module
