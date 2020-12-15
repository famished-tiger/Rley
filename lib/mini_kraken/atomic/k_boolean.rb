# frozen_string_literal: true

require_relative 'atomic_term'

module MiniKraken
  module Atomic
    # A specialized atomic term that implements a boolean (true/false) value
    # in MiniKraken.
    class KBoolean < AtomicTerm
      # Initialize a MiniKraken boolean with a given data value.
      # @example
      #   # Initialize with a Ruby boolean
      #   truthy = KBoolean.new(true)
      #   falsey = KBoolean.new(false)
      #   # Initialize with a String inspired from canonical miniKanren
      #   truthy = KBoolean.new('#t')   # In Scheme #t means true
      #   falsey = KBoolean.new('#f')   # In Scheme #f means false
      #   # Initialize with a Symbol inspired from canonical miniKanren
      #   truthy = KBoolean.new(:"#t")   # In Scheme #t means true
      #   falsey = KBoolean.new(:"#f")   # In Scheme #f means false
      # @param aValue [Boolean, String, Symbol] Ruby representation of boolean value.
      def initialize(aValue)
        super(validated_value(aValue))
      end

      private

      def validated_value(aValue)
        case aValue
          when true, false
            aValue
          when :"#t", '#t'
            true
          when :"#f", '#f'
            false
          else
            raise StandardError, "Invalid boolean literal '#{aValue}'"
        end
      end
    end # class
  end # module
end # module
