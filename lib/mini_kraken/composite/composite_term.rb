# frozen_string_literal: true

require_relative '../core/term'

module MiniKraken
  # This module packages the composite term classes.
  # These hold one or more MiniKanren objects.
  module Composite
    # An composite term is an Minikraken term that can be
    # decomposed into simpler MiniKraken data value(s).
    class CompositeTerm < Core::Term
      # Abstract method (to override). Return the child terms.
      # @return [Array<Term>]
      def children
        raise NotImplementedError, 'This method must re-defined in subclass(es).'
      end

=begin
      # @param env [Environment]
      # @return [Boolean]
      def fresh?(env)
        env.fresh_value?(self)
      end
=end
    end # class
  end # module
end # module
