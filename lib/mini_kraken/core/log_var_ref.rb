# frozen_string_literal: true

require 'set'
require_relative 'term'

module MiniKraken
  module Core
    # Representation of a reference to a MiniKraken logical variable.
    class LogVarRef < Term
      # @return [String] User-friendly name of the variable.
      attr_reader :name

      # @return [String] Unique internal name of the variable.
      attr_accessor :i_name

      # Create a reference to a logical variable with given name
      # @param aName [String] The name of the variable
      def initialize(aName)
        init_name(aName)
      end

      # Return a text representation of this logical variable reference.
      # @return [String]
      def to_s
        name
      end

      # Is the related log variable unbound in the given context?
      # A log var is unbound when there is no association for the variable.
      # @param aContext [Core::Context]
      # @return [Boolean] true if log var is unbound
      def unbound?(aContext)
        vr = aContext.lookup(name)
        raise StandardError, "Unknown variable #{name}" unless vr
        bindings = aContext.associations_for(name)
        bindings.empty? || (bindings.size == 1 && bindings[0].kind_of?(Fusion))
      end

      # Does the variable have at least one association AND
      # each of these association refer to at least one unbound variable
      # or a floating variable?
      # @param aContext [Core::Context]
      # @return [Boolean] true if log var is floating
      def floating?(aContext)
        vr = aContext.lookup(name)
        raise StandardError, "Unknown variable #{name}" unless vr
        assocs = aContext.associations_for(name)
        unless assocs.empty?
          assocs.none? { |as| as.pinned?(aContext) }
        else
          false
        end
      end

      # Is the variable pinned?
      # In other words, does the referenced variable have a definite value?
      # @param aContext [Core::Context]
      # @return [Boolean] true if log var is pinned
      def pinned?(aContext)
        return true if @pinned

        vr = aContext.lookup(name)
        raise StandardError, "Unknown variable #{name}" unless vr
        assocs = aContext.associations_for(name)
        unless assocs.empty?
          @pinned = assocs.all? { |as| as.pinned?(aContext) }
        else
          false
        end
      end

      # Return the list of variable (i_names) that this term depends on.
      # For a variable reference, it will return the i_names of its variable
      # @param ctx [Core::Context]
      # @return [Set<String>] a set containing the i_name of the variable
      def dependencies(ctx)
        @i_name ||= ctx.lookup(name).i_name
        s = Set.new
        s << i_name
        s
      end

      # Make a copy of self with all the variable reference being
      # replaced by the corresponding value in the Hash.
      # @param substitutions [Hash {String => Term}]
      # @return [Term]
      def dup_cond(substitutions)
        key = i_name ? i_name : name
        if substitutions.include? key
          val = substitutions[key]
          val.kind_of?(Term) ? val.dup_cond(substitutions) : val
        else
          self.dup
        end
      end

      private

      def init_name(aName)
        @name = aName.dup
      end
    end # class
  end # module
end # module
