# frozen_string_literal: true

require_relative '../../lib/mini_kraken/composite/list'

module MiniKraken
  # Mix-in module that provides convenience factory methods.
  module FactoryComposite
    # Factory method for constructing a ConsCell
    # @param obj1 [Term]
    # @param obj2 [Term]
    # @return [Core::ConsCell]
    def cons(obj1, obj2 = nil)
      Composite::List.cons(obj1, obj2)
    end
    
    # Factory method that build a proper list with given elements
    def make_list(*elems)
      Composite::List.make_list(elems)
    end
  end # module
end # module
