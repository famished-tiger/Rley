# frozen_string_literal: true

require_relative 'term'
require_relative 'specification'

module MiniKraken
  module Core
    # A specialization of Term class for objects that take arguments.
    class ParametrizedTerm < Term
      # @return [Specification] The specification that must be invoked with arguments.
      attr_reader :specification

      # @return [Array<Term>] The actual aguments of the goal
      attr_reader :actuals

      # Constructor.
      # @param theSpecification [Specification] The callable object.
      # @param theArgs [Array<Term>] The actual aguments
      def initialize(theSpecification, theArgs)
        super()
        @specification = validated_specification(theSpecification)
        args = specification.check_arity(theArgs)
        @actuals = validated_actuals(args)
      end

      def initialize_copy(orig)
        @specification = orig.specification
        @actuals = []
      end

      # Make a copy of self with all the variable reference being
      # replaced by the corresponding value in the Hash.
      # @param substitutions [Hash {String => Term}]
      # @return [Term]
      def dup_cond(substitutions)
        duplicate = dup
        duplicate.actuals.concat actuals.map { |e| e.dup_cond(substitutions) }

        duplicate
      end

      protected

      def validated_specification(theSpecification)
        unless theSpecification.kind_of?(Specification)
          msg_part1 = 'Expected kind_of Specification,'
          msg_part2 = "instead of #{theSpecification.class}."
          raise StandardError, msg_part1 + ' ' + msg_part2
        end

        theSpecification
      end

      # This method should be overridden in subclasses
      def validated_actuals(args)
        args
      end
    end # class
  end # module
end # module
