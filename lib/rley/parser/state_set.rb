require 'forwardable' # Delegation

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
  
    class StateSet
      extend Forwardable
      def_delegators :states, :empty?, :size, :first, :each
      
      # The set of parse states
      attr_reader(:states)
      
    
      def initialize()
        @states = []
      end
      
      def add_state(aState)
        @states << aState
      end

    end # class
  
  end # module
end # module

# End of file