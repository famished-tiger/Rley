# frozen_string_literal: true

require_relative 'association_copy'
require_relative 'bookmark'
require_relative 'fusion'

module MiniKraken
  module Core
    # A data structure that keeps the progress of a MiniKraken search.
    class Blackboard
      # This Hash answers to the question: given an i_name, what are
      # its related moves (associations, fusions) ?
      # @return [Hash{String=>Array<Integer>}] LIFO queue
      attr_reader :i_name2moves

      # A mapping from fused variable's i_name to a combining variable i_name
      # @return [Hash{String => String}]
      attr_reader :vars2cv

      # A stack of indices of bookmarks. The indices corresponds to
      # the positions of the bookmarks on the move_queue.
      # The events that involve bookmarks are:
      # - enter_scope       (when executing fresh expression)
      # - leave_scope       (when all solutions for given scope found)
      # - add_bk_point      (when a backtrack point must be added)
      # - remove_bk_point   (when a backtrack point must be retracted)
      # - next_alternative  (when a new solution is searched)
      # - fail!             (when the current solution fails)
      # @return [Array<Integer>]
      attr_reader :bookmarks

      # Serial numbers are assigned sequentially to bookmark objects.
      # This attribute holds the next available serial number.
      # @return [Integer] Next serial number to assign
      attr_reader :next_serial_num

      # A queue of entries that embodies the progress towards a solution.
      # @return [Array<Association, Bookmark, Fusion>]
      attr_reader :move_queue

      # @return [Symbol] One of: :"#s" (success), :"#u" (failure)
      attr_reader :resultant

      # Constructor.
      def initialize
        @i_name2moves = {}
        @vars2cv = {}
        # @bookmarks = []
        @next_serial_num = 0
        @move_queue = []
      end

      # Returns iff there is no entry in the association queue
      # @return [Boolean]
      def empty?
        move_queue.empty?
      end

      # Does the latest result represent a failure?
      # @return [Boolean] true if failure, false otherwise
      def failure?
        resultant != :"#s"
      end

      # Does the latest result represent a success?
      # @return [Boolean] true if success, false otherwise
      def success?
        resultant == :"#s"
      end

      # Return the most recent move.
      # @return [Association, Bookmark, Fusion]
      def last_move
        move_queue.last
      end

      # Indicate whether the variable is fused with another one
      # @param iName [String] Internal name of a logical variable      
      # @return [Boolean]
      def fused?(iName)
        vars2cv.include? iName
      end
      
      # If the variable is fused, then return the internal name of the
      # combining variable, otherwise return the input value as is.
      # @param iName [String] Internal name of a logical variable
      # @return [String] Internal name of variable or combining variable.
      def relevant_i_name(iName)
        fused?(iName) ? vars2cv[iName] : iName
      end

      # Retrieve the associations for the given internal name.
      # If requested, add the association(s) shared through the fusion
      # with another variable.
      # @param iName [String] Internal name of variable
      # @param shared [Boolean]
      # @return [Array<Association>]
      def associations_for(iName, shared = false)
        assocs_idx = nil
        if shared && fused?(iName)        
          assocs_idx = i_name2moves[vars2cv[iName]]
          if assocs_idx && move_queue[assocs_idx.first].kind_of?(Fusion)
              assocs_idx = assocs_idx.dup
              assocs_idx.shift
          end
        else
          indices = i_name2moves[iName]
          assocs_idx = indices.dup if indices
        end

        if assocs_idx
          assocs_idx.map { |i| move_queue[i] }
        else
          []
        end
      end

      # Push the given association onto the move queue
      # @param anAssociation [Association]
      # @return [Association]
      def enqueue_association(anAssociation)
        unless anAssociation.kind_of?(Association)
          raise StandardError, "Unsupported item class #{anAssociation.class}"
        end

        enqueue_move(anAssociation)
        anAssociation
      end

      # Push the given fusion object onto the move queue
      # @param aFusion [Fusion]
      # @return [Fusion]
      def enqueue_fusion(aFusion)
        aFusion.elements.each do |fused_i_nm|
          vars2cv[fused_i_nm] = aFusion.i_name
        end
        enqueue_move(aFusion)

        # If there is any existing association for the fused variables...
        # Add them to the associations of the combining variables
        bound = aFusion.elements.select { |i_nm| i_name2moves.include? i_nm }
        unless bound.empty?
          bound.each do |i_nm|
            to_copy = i_name2moves[i_nm]
            to_copy.each do |i|
              as = move_queue[i]
              new_as = AssociationCopy.new(aFusion.i_name, as)
              enqueue_association(new_as)
            end
          end
        end

        aFusion
      end

      # Notification of failure of last executed goal.
      # All moves up to most recent backtrack point are dropped.
      def failed!
        @resultant = :"#u"

        # Remove all items until most recent backtrack point.
        until move_queue.empty? ||
          (last_move.kind_of?(Bookmark) && last_move.kind == :bt_point) do
          dequeue_item
        end
      end

      # Notify success of last executed goal
      def succeeded!
        @resultant = :"#s"
      end

      # Place a backtrack point as a bookmark on move queue.
      # @return [Integer] serial number of created bookmark
      def place_bt_point
        add_bookmark(:bt_point)
      end
      
      # Remove all items until most recent backtrack bookmark found.
      # The boobmark is not remove from the queue
      # @return [Array<Association, Bookmark, Fusion>]       
      def next_alternative
        removed = []

        # Remove all items until most recent scope bookmark.
        until move_queue.empty? ||
          (last_move.kind_of?(Bookmark) && last_move.kind == :bt_point) do
         removed << dequeue_item
        end

        removed       
      end
      
      # Remove all items until most recent backtrack bookmark found.
      # @return [Array<Association, Bookmark, Fusion>]      
      def retract_bt_point
        removed = next_alternative
        dequeue_item unless move_queue.empty? # Remove the bookmark (if any)

        removed      
      end

      # React to event 'enter_scope' by putting a scope bookmark on move queue.
      # @return [Integer] serial number of created bookmark
      def enter_scope
        add_bookmark(:scope)
      end

      # Remove all items until most recent scope bookmark found.
      # @return [Array<Association, Bookmark, Fusion>]
      def leave_scope
        removed = []

        # Remove all items until most recent scope bookmark.
        until move_queue.empty? ||
          (last_move.kind_of?(Bookmark) && last_move.kind == :scope) do
         removed << dequeue_item
        end
        dequeue_item unless move_queue.empty? # Remove the bookmark (if any)

        removed
      end

      private

      # Push given move onto the queue and update the lookups.
      # @param [aMove [Association, Fusion]
      def enqueue_move(aMove)
        last_index = move_queue.size
        move_queue.push(aMove)
        iname = aMove.i_name
        if i_name2moves.include?(iname)
          i_name2moves[iname] << last_index
        else
          i_name2moves[iname] = [last_index]
        end

        aMove
      end

      # Remove the last item inserted in the queue
      # @return [Association, Bookmark, Fusion] Last item removed from LIFO queue
      def dequeue_item
        result = nil

        # require 'debug'
        return result unless last_move

        result = case last_move
          when Association
            dequeue_move
          when Bookmark
            remove_bookmark
          when Fusion
            remove_fusion
        end

        return result
      end

      # Low-level bookmark addition method.
      # @param aKind [Symbol] One of: :scope, :bt_point
      # @return [Integer] Serial number of new bookmark
      def add_bookmark(aKind)
        before_size = move_queue.size
        serial_number = next_serial_num
        @move_queue << Bookmark.new(aKind, serial_number)
        @next_serial_num += 1
        # @bookmarks << before_size

        serial_number
      end

      # Low-level association removal method.
      # Pre-condition: association to remove is on top of stack
      def dequeue_move
        unless last_move.kind_of?(Association) || last_move.kind_of?(Fusion)
          raise StandardError, 'Expected Assocation or Fusion on top of stack.'
        end

        i_name = last_move.i_name
        assocs_idx = i_name2moves[i_name]

        idx_last = assocs_idx.pop
        unless idx_last == (move_queue.size - 1)
          raise StandardError, 'Internal error'
        end

        i_name2moves.delete(i_name) if assocs_idx.empty?
        move_queue.pop
      end

      # Low-level bookmark removal method.
      # Pre-condition: bookmark to remove is on top of stack
      def remove_bookmark
        unless move_queue.last.kind_of?(Bookmark)
          raise StandardError, 'Expected a bookmark on top of stack.'
        end
        move_queue.pop
      end

      # Low-level fusion removal method.
      # Pre-condition: fusion to remove is on top of stack
      def remove_fusion
        unless  last_move.kind_of?(Fusion)
          raise StandardError, 'Fusion on top of stack.'
        end
        last_move.elements.each { |e| vars2cv.delete(e) }

        dequeue_move
      end
    end # class
  end # module
end # module
