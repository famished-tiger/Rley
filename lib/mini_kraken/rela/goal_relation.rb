# frozen_string_literal: true

require_relative '../core/goal'
require_relative '../core/relation'

module MiniKraken
  module Rela
    # A specialization of a relation that accepts only goal(s)
    # as its arguments.
    class GoalRelation < Core::Relation
      protected

      # Validate that actuals
      def validated_args(actuals)
        actuals.each do |arg|
          unless arg.kind_of?(Core::Goal)
            prefix = "#{name} expects goal as argument, found a "
            raise StandardError, prefix + "'#{arg.class}': #{arg}"
          end
        end

        actuals
      end
    end # class
  end # module
end # module
