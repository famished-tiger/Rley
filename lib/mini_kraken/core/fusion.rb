# frozen_string_literal: true


module MiniKraken
  module Core
    # A record of the fusion / merge of two or more logical variables.
    class Fusion
      # @return [String] i_name of substituting variable.
      attr_reader :i_name
      
      # @return [Array<String>] i_names of variables being substituted
      attr_reader :elements
      
      # Records the fusion of two or more logical variables.
      # The fused variables are substituted by a new variable
      # @param aName [String] Internal name of the substituting variable
      # @param fused [Array<String>] The i_names of the fused variables
      def initialize(aName, fused)
        @i_name = aName
        @elements = fused
      end
      
      # @return [Set] The empty set
      def dependencies(_ctx)
        @dependencies ||= Set.new(elements)
      end
    end # class
  end # module
end # module
