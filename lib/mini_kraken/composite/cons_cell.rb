# frozen_string_literal: true
require 'set'

require_relative 'composite_term'
require_relative 'cons_cell_visitor'

module MiniKraken
  module Composite
    # In Lisp dialects, a cons cell (or a pair) is a data structure with two
    # fields named car and cdr (for historical reasons).
    # Cons cells are the key ingredient for building lists in Lisp.
    # A cons cell can be depicted as a box with two parts, car and cdr each
    # containing a reference to another object.
    #   +-----------+
    #   | car | cdr |
    #   +--|-----|--+
    #      |     |
    #      V     V
    #     obj1  obj2
    #
    # The list (1 2 3) can be constructed as follows:
    #   +-----------+
    #   | car | cdr |
    #   +--|-----|--+
    #      |     |
    #      V     V
    #      1  +-----------+
    #         | car | cdr |
    #         +--|-----|--+
    #            |     |
    #            V     V
    #            2  +-----------+
    #               | car | cdr |
    #               +--|-----|--+
    #                  |     |
    #                  V     V
    #                  3    nil
    class ConsCell < CompositeTerm
      # The first slot in a ConsCell
      # @return [Term]
      attr_reader :car

      # The second slot in a ConsCell
      # @return [Term]
      attr_reader :cdr

      # Construct a new conscell whose car and cdr are obj1 and obj2.
      # In Scheme, a list is terminated by a null list.
      # In MiniKraken, a list is terminated by a Ruby nil.
      # Therefore, when setting the cdr to the null list, the implementation
      # will silently replace the null list by a nil.
      # @param obj1 [Term, NilClass]
      # @param obj2 [Term, NilClass]
      def initialize(obj1, obj2 = nil)
        super()
        @car = obj1
        if obj2.kind_of?(ConsCell) && obj2.null?
          @cdr = nil
        else
          @cdr = obj2
        end
      end

      # Specialized constructor for null list.
      # @return [ConsCell] Null list
      def self.null
        self.new(nil, nil)
      end

      def children
        [car, cdr]
      end

      # Return true if it is an empty list, otherwise false.
      # A list is empty, when both car and cdr fields are nil.
      # @return [Boolean]
      def null?
        car.nil? && cdr.nil?
      end

      # Is the receiver an unbound variable?
      # By definition, a composite isn't a variable.
      # @param _ctx [Core::Context]
      # @return [FalseClass]
      def unbound?(_ctx)
        false
      end

      # Does the composite have a variable that is itself floating?
      # @return [Boolean]
      def floating?(ctx)
        !pinned?(ctx)
      end

      # Does the composite have a definite value?
      # @return [Boolean]
      def pinned?(ctx)
        @pinned_car = car.nil? || car.pinned?(ctx) unless @pinned_car
        @pinned_cdr = cdr.nil? || cdr.pinned?(ctx) unless @pinned_cdr

        @pinned_car && @pinned_cdr
      end

      # Return true if car and cdr fields have the same values as the other
      # ConsCell.
      # @param other [ConsCell]
      # @return [Boolean]
      def ==(other)
        return false unless other.respond_to?(:car)

        (car == other.car) && (cdr == other.cdr)
      end

      # Test for type and data value equality.
      # @param other [ConsCell]
      # @return [Boolean]
      def eql?(other)
        (self.class == other.class) && car.eql?(other.car) && cdr.eql?(other.cdr)
      end

      # Return a data object that is a copy of the ConsCell
      # @param anEnv [Core::Environment]
      # @return [ConsCell]
      def quote(anEnv)
        return self if null?

        new_car = car.nil? ? nil : car.quote(anEnv)
        new_cdr = cdr.nil? ? nil : cdr.quote(anEnv)
        ConsCell.new(new_car, new_cdr)
      end

      # Use the list notation from Lisp as a text representation.
      # @return [String]
      def to_s
        return '()' if null?

        "(#{pair_to_s})"
      end

      # Return the list of variable (i_names) that this term depends on.
      # For a variable reference, it will return the i_names of its variable
      # @param ctx [Core::Context]
      # @return [Set<String>] A set of i_names
      def dependencies(ctx)
        deps = []
        visitor = ConsCellVisitor.df_visitor(self)
        skip_children = false
        loop do
          side, cell = visitor.resume(skip_children)
          if cell.kind_of?(Core::LogVarRef)
            deps << ctx.lookup(cell.name).i_name
            skip_children = true
          else
            skip_children = false
          end
          break if side == :stop
        end

        Set.new(deps)
      end


      # @param ctx [Core::Context]
      # @param theSubstitutions [Hash{String => Association}]
      def expand(ctx, theSubstitutions)
        head = curr_cell = nil
        path = []

        visitor = ConsCellVisitor.df_visitor(self) # Breadth-first!
        skip_children = false

        loop do
          side, cell = visitor.resume(skip_children)
          # next if cell == self
          break if side == :stop

          case cell
            when ConsCell
              new_cell = ConsCell.null
              if curr_cell
                curr_cell.set!(side, new_cell)
                path.push(curr_cell)
              end            
              curr_cell = new_cell
              head ||= new_cell

            when Core::LogVarRef
              # Is this robust?
              if cell.i_name
                i_name = cell.i_name
              else
                i_name = ctx.symbol_table.lookup(cell.name).i_name
              end
              expanded = ctx.expand_value_of(i_name, theSubstitutions)
              curr_cell.set!(side, expanded)
              curr_cell = path.pop if side == :cdr

            else
              curr_cell.set!(side, cell)
              curr_cell = path.pop if side == :cdr
          end
        end

        head
      end
      
      
      # @param ctx [Core::Context]
      # @param theSubstitutions [Hash{String => Association}]


      # File 'lib/mini_kraken/atomic/atomic_term.rb', line 91
      # Make a copy of self with all the variable reference being replaced 
      # by the corresponding value in the Hash.
      # @param substitutions [Hash {String => Term}]
      # @return [ConsCell]
      def dup_cond(substitutions)      
        head = curr_cell = nil
        path = []

        visitor = ConsCellVisitor.df_visitor(self) # Breadth-first!
        skip_children = false

        loop do
          side, cell = visitor.resume(skip_children)
          # next if cell == self
          break if side == :stop

          if cell.kind_of?(ConsCell)
            new_cell = ConsCell.null
            if curr_cell
              curr_cell.set!(side, new_cell)
              path.push(curr_cell)
            end            
            curr_cell = new_cell
            head ||= new_cell

          else
            duplicate = cell.nil? ? nil : cell.dup_cond(substitutions)
            curr_cell.set!(side, duplicate)
            curr_cell = path.pop if side == :cdr
          end
        end

        head
      end      

      # Set one element of the pair
      # @param member [Symbol]
      # @param element [Term]
      def set!(member, element)
        case member
          when :car
            set_car!(element)
          when :cdr
            @pinned_cdr = nil
            @cdr = element
          else
            raise StandardError, "Undefined cons cell member #{member}"
          end
      end

      # Change the car of ConsCell to 'element'.
      # Analogue of set-car! procedure in Scheme.
      # @param element [Term]
      def set_car!(element)
        @pinned_car = nil # To force re-evaluation
        @car = element
      end

      # Change the cdr of ConsCell to 'element'.
      # Analogue of set-cdr! procedure in Scheme.
      # @param element [Term]
      def set_cdr!(element)
        @pinned_cdr = nil # To force re-evaluation
        @cdr = (element.kind_of?(ConsCell) && element.null?) ? nil : element
      end

      protected

      def pair_to_s
        result = +car.to_s
        if cdr
          result << ' '
          if cdr.kind_of?(ConsCell)
            result << cdr.pair_to_s
          else
            result << ". #{cdr}"
          end
        end

        result
      end
    end # class

    # Constant set to a null (empty) list.
    NullList = ConsCell.null.freeze
  end # module
end # module
