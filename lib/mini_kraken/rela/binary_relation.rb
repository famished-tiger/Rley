# frozen_string_literal: true

require_relative '../core/relation'

module MiniKraken
  module Rela
    # A binary relation between sets X and Y is a subset of the Cartesian product
    # X × Y; that is, it is a set of ordered pairs (x, y) consisting of elements
    # x in X and y in Y.
    class BinaryRelation < Core::Relation
      # @param aName [String] Name of the relation.
      def initialize(aName)
        super(aName, 2)
        freeze
      end

      def self.symmetric
        define_method :commute_cond do |arg1, arg2, ctx|
          w1 = weight_arg(arg1, ctx)
          w2 = weight_arg(arg2, ctx)
          if w2 > w1
            [arg2, arg1]
          else
            [arg1, arg2]
          end
        end
      end
    end # class
  end # module
end # module
