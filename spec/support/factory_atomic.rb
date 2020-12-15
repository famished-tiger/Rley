# frozen_string_literal: true

require_relative '../../lib/mini_kraken/atomic/all_atomic'

module MiniKraken
  # Mix-in module that provides convenience factory methods.
  module FactoryAtomic
    # Factory method for constructing a KBoolean instance
    # @param aValue [Boolean]
    # @return [Core::KBoolean]
    def k_boolean(aValue)
      Atomic::KBoolean.new(aValue)
    end

    # Factory method for constructing a KString instance
    # @param aString [String]
    # @return [Core::KSymbol]
    def k_string(aString)
      Atomic::KString.new(aString)
    end

    # Factory method for constructing a KSymbol instance
    # @param aSymbol [Symbol]
    # @return [Core::KSymbol]
    def k_symbol(aSymbol)
      Atomic::KSymbol.new(aSymbol)
    end
  end # end
end # module
