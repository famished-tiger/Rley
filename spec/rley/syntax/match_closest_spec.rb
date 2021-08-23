# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/symbol_seq'

# Load the class under test
require_relative '../../../lib/rley/syntax/production'

# Load the class under test
require_relative '../../../lib/rley/syntax/match_closest'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe MatchClosest do
      # 'stmt' => 'IF boolean THEN stmt ELSE stmt'
      let(:boolean) { NonTerminal.new('boolean') }
      let(:stmt) { NonTerminal.new('stmt') }
      let(:if_t) { Terminal.new('IF') }
      let(:then_t) { Terminal.new('THEN') }
      let(:else_t) { Terminal.new('ELSE') }
      let(:sequence) { [if_t, boolean, then_t, stmt, else_t, stmt] }
      let(:prod) { Production.new(stmt, sequence) }

      subject { MatchClosest.new(prod.rhs.members, 4, 'IF') }

      context 'Initialization:' do
        it 'should be created with an symbol seq., an indice and a name' do
          expect { MatchClosest.new(prod.rhs.members, 4, 'IF') }.not_to raise_error
        end

        it 'should know the index argument' do
          expect(subject.idx_symbol).to eq(4) # ELSE at position 4
        end

        it 'should know the name of preceding symbol to pair with' do
          expect(subject.closest_symb).to eq('IF')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
