# frozen_string_literal: true

require_relative '../../lib/mini_kraken/core/any_value'
require_relative '../../lib/mini_kraken/atomic/all_atomic'
require_relative '../../lib/mini_kraken/composite/cons_cell'
require_relative '../../lib/mini_kraken/core/log_var'
require_relative '../../lib/mini_kraken/core/log_var_ref'

module MiniKraken
  # Mix-in module that provides convenience factory methods.
  module FactoryMethods
    # Factory method for constructing an AnyValue instance
    # @param rank [Integer]
    # @return [Core::AnyValue]
    def any_value(rank)
      any_val = Core::AnyValue.allocate
      any_val.instance_variable_set(:@rank, rank)
      any_val
    end

    # Factory method for constructing a ConsCell
    # @param obj1 [Term]
    # @param obj2 [Term]
    # @return [Core::ConsCell]
    def cons(obj1, obj2 = nil)
      Composite::ConsCell.new(obj1, obj2)
    end

    # Factory method for constructing a goal using the Equals relation.
    # @param args [Array<Core::Goal>]
    # @return [Core::Goal]
    def conde_goal(args)
      Core::Goal.new(Core::Conde.instance, args)
    end

    # Factory method for constructing a goal using the Equals relation.
    # @param arg1 [Term]
    # @param arg2 [Term]
    # @return [Core::Goal]
    def equals_goal(arg1, arg2)
      Core::Goal.new(Core::Equals.instance, [arg1, arg2])
    end

    # Factory method for constructing a goal using the conjunction relation.
    # @param g1 [Core::Goal]
    # @param g2 [Core::Goal]
    # @return [Core::Goal]
    def conj2_goal(g1, g2)
      Core::Goal.new(Core::Conj2.instance, [g1, g2])
    end

    # Factory method for constructing a goal using the disjunction relation.
    # @param g1 [Core::Goal]
    # @param g2 [Core::Goal]
    # @return [Core::Goal]
    def disj2_goal(g1, g2)
      Core::Goal.new(Core::Disj2.instance, [g1, g2])
    end

    # Factory method for constructing a LogVar
    # @param var_name [String]
    # @return [Core::LogVar]
    def variable(var_name)
      Core::LogVar.new(var_name)
    end

    # Factory method for constructing a LogVarRef
    # @param var_name [String]
    # @return [Core::LogVarRef]
    def var_ref(var_name)
      Core::LogVarRef.new(var_name)
    end
  end # end
end # module
