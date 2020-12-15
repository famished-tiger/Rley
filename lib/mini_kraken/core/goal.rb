# frozen_string_literal: true

require_relative 'parametrized_term'
require_relative 'context'

module MiniKraken
  module Core
    class Goal < ParametrizedTerm
      alias relation specification      

      # @param aRelation [Relation] The relation corresponding to this goal
      # @param args [Array<Term>] The actual aguments of the goal   
      def initialize(aRelation, args)
        super(aRelation, args)
      end

      # Attempt to obtain one or more solutions for the goal in a given context.
      # @param ctx [Core::Context] The context in which the goal takes place.
      # @return [Fiber<Context>] A Fiber object that will generate the results.
      def achieve(ctx)
        solver = relation.solver_for(actuals, ctx)
        solver
      end

      private

      def validated_specification(theSpec)
        spec = super(theSpec)
        unless spec.kind_of?(Relation)
          raise StandardError, "Expected a Relation instead of #{theSpec.class}."
        end

        spec
      end

      def validated_actuals(args)
        args.each do |actual|
          if actual.kind_of?(Term) || actual.respond_to?(:attain)
            next
          elsif actual.kind_of?(Array)
            validated_actuals(actual)
          else
            prefix = 'Invalid goal argument'
            actual_display = actual.nil? ? 'nil' : actual.to_s
            raise StandardError, "#{prefix} '#{actual_display}'"
          end
        end

        args.dup
      end
    end # class
  end # module
end # module
