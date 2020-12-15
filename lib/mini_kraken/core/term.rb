# frozen_string_literal: true

require_relative 'base_term'

module MiniKraken
  module Core
    # The generalization of any object that can be:
    #   - passed as argument to a goal.
    #   - passed as argument to a MiniKraken procedure
    #   - contained in a compositer term,
    #   - associated with a logical variable.
    class Term < BaseTerm
      # Abstract method.
      # Make a copy of self with all the variable reference being
      # replaced by the corresponding value in the Hash.
      # @param substitutions [Hash {String => Term}]
      # @return [Term]
      def dup_cond(substitutions)
        raise NotImplementedError, "Not implementation for #{self.class}."
      end
    end # class
  end # module
end # module
