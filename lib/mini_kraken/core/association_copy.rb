# frozen_string_literal: true

require_relative 'association'

module MiniKraken
  module Core
    # A specialized association that bind a variable to a value from another 
    # association.
    class AssociationCopy < Association
      # @return [String] internal name of variable being associated the value.
      attr_accessor :i_name

      # @return [Association] the association from which the value is shared.
      attr_reader :source

      # @param aVariable [Variable, String] A variable or its internal name.
      # @param anAssoc [Association] an association that shares its value.
      def initialize(aVariable, anAssoc)
        super(aVariable, nil)
        @source = anAssoc
      end

      # Is the associated value floating, that is, it does contain
      # a variable that is either unbound or floating?
      # @param ctx [Core::Context]
      # @return [Boolean]
      def floating?(ctx)
        source.floating?(ctx)
      end

      # Is the associated value pinned, that is, doesn't contain
      # an unbound or floating variable?
      # @param ctx [Core::Context]
      # @return [Boolean]
      def pinned?(ctx)
        source.pinned?(ctx)
      end
 
      # @return [Term] the MiniKraken value associated with the variable 
      def value
        source.value
      end
      
      # @return [Array<String>] The i_names of direct dependent variables      
      def dependencies(ctx)
         source.dependencies(ctx)
      end
    end # class
  end # module
end # module
