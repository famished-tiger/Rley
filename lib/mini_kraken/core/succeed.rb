# frozen_string_literal: true

require 'singleton'
require_relative 'duck_fiber'
require_relative 'nullary_relation'

module MiniKraken
  module Core
    # A nullary relation that always returns success outcomes.
    class Succeed < NullaryRelation
      include Singleton

      # Constructor. Initialize the relation's name & freeze it...
      def initialize
        super('succeed')
      end

      # Returns a Fiber-like object (a DuckFiber).
      # When that object receives the message resume, it will
      # return a success context.
      # @param actuals [Array] MUST be empty array for nullary relation.
      # @param ctx [Core::Context] Runtime context
      # @return [Core::DuckFiber]
      def solver_for(actuals, ctx)
        # Important: every `solver_for` call will result in a distinct Context.
        DuckFiber.new(-> { ctx.succeeded! })
      end
    end # class
  end # module
end # module
