# frozen_string_literal: true

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A constraint that indicates that a given rhs member must
    # match the closest given terminal symbol in that rhs
    class MatchClosest
      # @return [Integer] index of constrained symbol to match
      attr_reader(:idx_symbol)

      # @return [String] name of closest preceding symbol to pair
      attr_reader(:closest_symb)

      # @return [NilClass, Array<Parser::ParseEntry>] set of entries with closest symbol
      attr_accessor(:entries)

      # @param aSymbolSeq [Rley::Syntax::SymbolSeq] a sequence of grammar symbols
      # @param idxSymbol [Integer] index of symbol
      # @param nameClosest [String] Terminal symbol name
      def initialize(aSymbolSeq, idxSymbol, nameClosest)
        @idx_symbol = valid_idx_symbol(idxSymbol, aSymbolSeq)
        @closest_symb = valid_name_closest(nameClosest)
      end

      private

      # Check that the provided index is within plausible bounds
      def valid_idx_symbol(idxSymbol, aSymbolSeq)
        bounds = 0..aSymbolSeq.size - 1
        err_msg_outbound = 'Index of symbol out of bound'
        raise StandardError, err_msg_outbound unless bounds.include? idxSymbol

        idxSymbol
      end

      def valid_name_closest(nameClosest)
        nameClosest
      end
    end # class
  end # module
end # module

# End of file
