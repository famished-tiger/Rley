# frozen_string_literal: true

require_relative 'log_var'

module MiniKraken
  module Core
    # A scope is a name space that corresponds either to a specific
    # delimited region in MiniKraken source code or to an activation record
    # of a relation or a relation definition.
    # It contains a map of names to the objects they name (e.g. logical var)
    class Scope
      # The parent (enclosing) scope.
      # @return [Scope, NilClass]
      attr_accessor :parent

      # Mapping from user-defined name to related definition
      #  (say, a logical variable object)
      # @return [Hash{String => LogVar}] Pairs of the kind 
      attr_reader :defns

      # Construct a scope instance.
      # TODO: extend with defrel and procedure
      # @param aParent [Scope, NilClass] Parent scope to this one.
      def initialize(aParent = nil)
        @parent = aParent
        @defns = {}
      end

      # Add a new logical variable to the scope.
      # @param anEntry [LogVar]
      # @return [LogVar] the variable
      def insert(anEntry)
        e = validated_entry(anEntry)
        e.suffix = default_suffix if e.kind_of?(LogVar)
        defns[e.name] = e

        e
      end

      # Returns a string with a human-readable representation of the object.
      # @return [String]
      def inspect
        result = +"#<#{self.class}:#{object_id.to_s(16)}>"
      end

      private

      def validated_entry(anEntry)
        name = anEntry.name
        unless name.kind_of?(String) && !name.empty?
          err_msg = "Invalid variable name argument."
          raise StandardError, err_msg
        end
        if defns.include?(name)
          err_msg = "Variable with name '#{name}' already exists."
          raise StandardError, err_msg
        end

        anEntry
      end

      def default_suffix
        @default_suffix ||= "_#{object_id.to_s(16)}"
      end
    end # class
  end # module
end # module
