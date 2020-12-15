# frozen_string_literal: true

require_relative 'atomic_term'

module MiniKraken
  module Atomic
    # A specialized atomic term that represents an integer value.
    # in MiniKraken
    # @note As MiniKraken doesn't support integer values yet, this class is WIP.
    class KInteger < AtomicTerm
      # @param aValue [Integer] Ruby representation of integer value
      def initialize(aValue)
        super(aValue)
      end
    end # class
  end # module
end # module
