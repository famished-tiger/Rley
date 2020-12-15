# frozen_string_literal: true

module MiniKraken
  module Core
    # Mix-in module that implements the expected common behaviour of entries
    # placed in the symbol table.
    module Entry
      # @return [String] User-defined name of the entry.
      attr_reader :name

      # @return [String] Suffix for building the internal name of the entry.
      attr_accessor :suffix

      alias label name

      # Initialize the entry with given name
      # @param aName [String] The name of the entry
      def init_name(aName)
        @name = aName.dup
        @name.freeze
      end

      # Return the internal name of the entry
      # Internal names used to disambiguate entry names.
      # There might be homonyns between variable because:
      #   - A child Scope may have a entry with same name as one of its
      #     ancestor(s).
      #   - Multiple calls to same defrel or procedure may imply multiple creation
      #     of a entry given name...
      # @return [String] internal name
      def i_name
        if suffix =~ /^_/
          label + suffix
        else
          (suffix.nil? || suffix.empty?) ? label : suffix
        end
      end
    end # module
  end # module
end # module
