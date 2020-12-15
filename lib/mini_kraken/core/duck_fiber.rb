# frozen_string_literal: true

require_relative 'context'

module MiniKraken
  module Core
    # A mock class that mimicks the behavior of a Fiber instance.
    # More specifically, it responds to `resume` message & returns a Context.
    class DuckFiber
      # @return [Proc, #call] The callable object to yield.
      attr_reader :callable

      # @return [Symbol] one of: :initial, :yielded
      attr_reader :state

      # Constructor.
      # @param aCallable [Proc, #call] The receiver of the 'call' message.
      def initialize(aCallable)
        @callable = valid_callable(aCallable)
        @state = :initial
      end

      # Quacks like a Fiber object.
      # The first time, this method will return a Context objet.
      # Subsequents calls just return nil (= no other solution available)
      # @return [Core::Context, NilClass]
      def resume(*_args)
        if state == :initial
          @state = :yielded
          return callable.call
        else
          return nil
        end
      end

      private

      def valid_callable(aCallable)
        unless aCallable.kind_of?(Proc) || aCallable.respond_to?(:call)
          err_msg = "Expected a Proc instead of #{aCallable.class}."
          raise StandardError, err_msg
        end

        aCallable
      end
    end # class
  end # module
end # module
