# frozen_string_literal: true

module MiniKraken
  module Core
    # A wrapper around a "solver" object.
    # A solver in MiniKraken is Fiber or an object that quacks like
    # a Fiber in that its has a 'resume' method.
    # To be a solver, the adaptee object must yield a Context or nil.
    # A SolverAdapter implements a customized resume method that
    # acts as an "execute around" method for the adaptee's ´resume´ method.
    class SolverAdapter
      # @return [#resume] A Fiber-like object as adaptee
      attr_reader :adaptee
      
      # ->(adapter, aContext) do
        # aContext.push_bookmark(adapter.adaptee)
        # result = adapter.adaptee.resume
        # aContext.pop_bookmark
        # result
      # end        
      # @return [Proc] lambda to execute when resume is called
      attr_reader :around_resume

      # Constructor.
      # @param fib [#resume] A Fiber-like object
      def initialize(fib, &blk)
        @adaptee = validated_adaptee(fib)
        @around_resume = blk if block_given?
      end

      # Update the bookmarks and resume the Fiber
      # @param aContext [Core::Context]
      # @return [Core::Context, NilClass]
      def resume(aContext)
        ctx = validated_ctx(aContext)
        if around_resume
          around_resume.call(self, ctx)
        else
          adaptee.resume
        end
      end

      private

      def validated_adaptee(fib)
        raise StandardError, "No resume method" unless fib.respond_to?(:resume)

        fib
      end

      def validated_ctx(aContext)
        raise StandardError unless aContext.kind_of?(Context)

        aContext
      end
    end # class
  end # module
end # module
