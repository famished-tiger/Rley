# frozen_string_literal: true

module MiniKraken
  module Core
    # A bookmark is a placeholder for events of significance for
    # manipulating the move queue of a blackboard.
    # The events that involve bookmarks are:
    # - enter_scope       (when executing fresh expression)
    # - leave_scope       (when all solutions for given scope were found)
    # - add_bt_point      (when a backtrack point must be added)
    # - remove_bt_point   (when a backtrack point must be retracted)
    # - next_alternative  (when an alternative solution is searched)
    # - fail!             (when the current solution fails)
    class Bookmark
      # @return [Symbol] One of: :scope, :bt_point
      attr_reader :kind

      # @return [Integer] An unique serial number.
      attr_reader :ser_num

      # @param aKind [Symbol] must be one of: :scope, :bt_point
      # @param aSerialNumber [Integer] a serial number
      def initialize(aKind, aSerialNumber)
        @kind = validated_kind(aKind)
        @ser_num = aSerialNumber
      end

      # Equality comparison
      # @param other [Bookmark, Object]
      # return [Boolean]
      def ==(other)
        ser_num == other.ser_num
      end

      private

      def validated_kind(aKind)
        if aKind != :scope && aKind != :bt_point
          raise StandardError, "Invalid kind: {aKind}"
        end

        aKind
      end
    end # class
  end # module
end # module
