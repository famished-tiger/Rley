# frozen_string_literal: true

require 'singleton'
require_relative 'binary_relation'

require_relative '../core/duck_fiber'
require_relative '../core/log_var_ref'
require_relative '../atomic/atomic_term'
require_relative '../composite/all_composite'


module MiniKraken
  module Rela
    # Corresponds to the '==' relation in canonical miniKanren implementation
    # in Scheme. Implements the core of the unification algorithm.
    class Unify < BinaryRelation
      include Singleton

      symmetric # Unify relation is symmetric ("First Law of ==")

      # Constructor. Initialize the name of the relation
      def initialize
        super('unify')
        freeze
      end

      # @param actuals [Array<Term>] A two-elements array
      # @param ctx [Context] A context object
      # @return [Fiber<Context>] A DuckFiber instance that yields one Context.
      def solver_for(actuals, ctx)
        arg1, arg2 = *actuals
        # context = unification(arg1, arg2, ctx)
        # Core::DuckFiber.new(-> { context })
        Core::DuckFiber.new(-> { unification(arg1, arg2, ctx) })
      end

      # @param arg1 [Term]
      # @param arg2 [Term]
      # @param ctx [Context] A context object
      # @return [Context] The updated context
      def unification(arg1, arg2, ctx)
        return ctx.succeeded! if arg1.equal?(arg2)
        return ctx.failed! if arg1.nil? || arg2.nil?

        new_arg1, new_arg2 = commute_cond(arg1, arg2, ctx)
        do_unification(new_arg1, new_arg2, ctx)
      end

      protected

      def do_unification(arg1, arg2, ctx)
        table = [
          # cond1                        cond2                          selector
          [ kind_of(Atomic::AtomicTerm), kind_of(Atomic::AtomicTerm),
            :unify_atomic_terms],
          [ kind_of(Composite::CompositeTerm), kind_of(Atomic::AtomicTerm),
            :unify_composite_atomic],
          [ kind_of(Composite::CompositeTerm), kind_of(Composite::CompositeTerm),
            :unify_composite_terms],
          [ kind_of(Core::LogVarRef), kind_of(Atomic::AtomicTerm),
            :unify_ref_atomic],
          [ kind_of(Core::LogVarRef), kind_of(Composite::CompositeTerm),
            :unify_ref_composite],
          [kind_of(Core::LogVarRef), kind_of(Core::LogVarRef),
            :unify_references]
        ]
        
        # require 'debug'

        table.each do |(cond1, cond2, selector)|
          if cell_success(arg1, cond1, ctx) &&
            cell_success(arg2, cond2, ctx)
            return send(selector, arg1, arg2, ctx)
          end
        end

        ctx.failed
      end

=begin
      # table: Commute
      # |arg1                | arg2               | arg2.ground? || Commute |
      # | isa? Atomic        | isa? Atomic        | dont_care    || Yes     |
      # | isa? Atomic        | isa? CompositeTerm | dont_care    || Yes     |
      # | isa? Atomic        | isa? LogVarRef   | dont_care    || Yes     |
      # | isa? CompositeTerm | isa? Atomic        | true         || No      |
      # | isa? CompositeTerm | isa? CompositeTerm | false        || Yes     |
      # | isa? CompositeTerm | isa? CompositeTerm | true         || No      |
      # | isa? CompositeTerm | isa? LogVarRef   | dont_care    || Yes     |
      # | isa? LogVarRef   | isa? Atomic        | dont_care    || No      |
      # | isa? LogVarRef   | isa? CompositeTerm | dont_care    || No      |
      # | isa? LogVarRef   | isa? LogVarRef   | false        || Yes     |
      # | isa? LogVarRef   | isa? LogVarRef   | true         || No      |
=end

      def weight_arg(arg, ctx)
        case arg
          when Atomic::AtomicTerm
            1
          when Composite::CompositeTerm
            2
          when Core::LogVarRef
            # Move unbound argument to the right...
            arg.unbound?(ctx) ? 3 : 4
          else
            raise StandardError
        end
      end

      def kind_of(aClass)
        ->(ar, _) { ar.kind_of?(aClass) }
      end

      private

      def cell_success(arg, cond, ctx)
        case cond
          when Class
            arg.class == cond.class
          when Proc
            cond.call(arg, ctx)
          else
            raise StandardError
        end
      end

      # Unification of two atomic terms
      # @param arg1 [Atomic::AtomicTerm]
      # @param arg2 [Atomic::AtomicTerm]
      # @param ctx [Core::Context] A context object
      # @return [Core::Context] Updated context
      def unify_atomic_terms(arg1, arg2, ctx)
        arg1.eql?(arg2) ? ctx.succeeded! : ctx.failed!
      end

      # Unification of a composite term with an atomic term
      # @param _composite [Composite::CompositeTerm]
      # @param _atomic [Atomic::AtomicTerm]
      # @param ctx [Core::Context] A context object
      # @return [Core::Context] a failure Context
      def unify_composite_atomic(_composite, _atomic, ctx)
        ctx.failed!
      end

      # Unification of a composite term with an atomic term
      # @param arg1 [Composite::CompositeTerm]
      # @param arg2 [Composite::CompositeTerm]
      # @param ctx [Core::Context] A context object
      # @return [Core::Context] Updated context
      def unify_composite_terms(arg1, arg2, ctx)
        return ctx.succeeded! if arg1.null? && arg2.null?
        # require 'debug'

        # We do parallel iteration
        visitor1 = Composite::ConsCellVisitor.df_visitor(arg1)
        visitor2 = Composite::ConsCellVisitor.df_visitor(arg2)
        skip_children1 = skip_children2 = false

        loop do
          # side.. can be: :car, :cdr, :stop
          side1, cell1 = visitor1.resume(skip_children1)
          side2, cell2 = visitor2.resume(skip_children2)
          if side1 != side2
            ctx.failed
          elsif side1 == :stop
            break
          else
            # A cell can be: nil, Atomic::AtomicTerm, Composite::ConsCell, LogVarRef
            case [cell1.class, cell2.class]
              when [Composite::ConsCell, Composite::ConsCell]
                skip_children1 = skip_children2 = false
                ctx.blackboard.succeeded!
              when [Composite::ConsCell, Core::LogVarRef]
                skip_children1 = true
                skip_children2 = false
                unification(cell1, cell2, ctx)
              when [Core::LogVarRef, Composite::ConsCell]
                skip_children1 = false
                skip_children2 = true
                sub_result = do_unification(cell1, cell2, ctx)
            else
              skip_children1 = skip_children2 = false
              unification(cell1, cell2, ctx)
            end
          end

          break if ctx.failure?
        end

        ctx
      end

      # Unification of a logical variable reference with an atomic term
      # @param ref [Core::LogVarRef]
      # @param atomic [Atomic::AtomicTerm]
      # @param ctx [Core::Context] A context object
      # @return [Core::Context] Updated context
      def unify_ref_atomic(ref, atomic, ctx)
        if ref.unbound?(ctx)
          ctx.associate(ref, atomic)
          ctx.succeeded!
        else
          assocs = ctx.associations_for(ref.name)
          first_assoc = assocs.first
          if first_assoc.kind_of?(Core::Association) &&
            first_assoc.value.eql?(atomic)
            # Trying to associate again to the same value is OK
            ctx.succeeded!
          else
            ctx.failed!
          end
        end
      end

      # Unification of a logical variable and a composite
      # @param ref [Core::LogVarRef]
      # @param composite [Core::CompositeTerm]
      # @param ctx [Core::Context] A context object
      # @return [Core::Context] Updated context
      def unify_ref_composite(ref, composite, ctx)
        if ref.unbound?(ctx)
          ctx.associate(ref, composite)
          ctx.succeeded!
        else
          # Assumption: ref has only one existing association...
          as = ctx.associations_for(ref.name)
          first_assoc = as.first.value
          result = unification(first_assoc, composite, ctx)
          return ctx if ctx.failure?

          # The association can be sometimes be redundant...
          ctx.associate(ref, composite) unless first_assoc.pinned?(ctx)
          ctx.succeeded!
        end

        ctx
      end

      # Unification of two logical variable references
      # @param ref1 [Core::LogVarRef]
      # @param ref2 [Core::LogVarRef]
      # @param ctx [Core::Context] A context object
      # @return [Core::Context] Updated context
      def unify_references(ref1, ref2, ctx)
        return ctx.succeeded! if ref1.name == ref2.name
        if ref1.unbound?(ctx) || ref2.unbound?(ctx)
          ctx.fuse([ref1.name, ref2.name])
          ctx.succeeded!
        else
          raise NotImplentedError
        end
        # if both refs are fresh, fuse them
        # if one ref is fresh & the other one isn't then bind fresh one (occurs check)
        # More cases...

        ctx
      end

    end # class
  end # module
end # module