# frozen_string_literal: true

require_relative 'relation'

module MiniKraken
  module Core
    class NullaryRelation < Relation
      # @param aName [String] Name of the relation.
      def initialize(aName)
        super(aName, 0)
        freeze
      end
    end # class
  end # module
end # module
