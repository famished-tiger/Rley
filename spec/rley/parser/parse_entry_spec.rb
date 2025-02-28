# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/base/dotted_item'

# Load the class under test
require_relative '../../../lib/rley/parser/parse_entry'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe ParseEntry do
      # Default instantiation rule
      subject(:an_entry) { described_class.new(sample_vertex, origin_val) }

      let(:t_a) { Syntax::Terminal.new('A') }
      let(:t_b) { Syntax::Terminal.new('B') }
      let(:t_c) { Syntax::Terminal.new('C') }
      let(:nt_sentence) { Syntax::NonTerminal.new('sentence') }

      let(:sample_prod) do
        Syntax::Production.new(nt_sentence, [t_a, t_b, t_c])
      end

      let(:empty_prod) do
        Syntax::Production.new(nt_sentence, [])
      end

      let(:dotted_rule) { Base::DottedItem.new(sample_prod, 2) }
      let(:origin_val) { 3 }
      let(:sample_vertex) { GFG::StartVertex.new(nt_sentence) }
      let(:vertex2) { double('vertex-mock') }


      context 'Initialization:' do
        it 'is created with a vertex and an origin position' do
          args = [sample_vertex, origin_val]
          expect { described_class.new(*args) }.not_to raise_error
        end

        it 'complains when the vertex is nil' do
          err = StandardError
          msg = 'GFG vertex cannot be nil'
          expect { described_class.new(nil, 2) }.to raise_error(err, msg)
        end

        it 'knows the vertex' do
          expect(an_entry.vertex).to eq(sample_vertex)
        end

        it 'knows the origin value' do
          expect(an_entry.origin).to eq(origin_val)
        end

        it 'has not antecedent at creation' do
          expect(an_entry.antecedents).to be_empty
          expect(an_entry).to be_orphan
        end
      end # context

      context 'Provided services:' do
        it 'compares with itself' do
          synonym = an_entry # Fool Rubocop
          expect(an_entry == synonym).to be(true)
        end

        it 'compares with another' do
          equal = described_class.new(sample_vertex, origin_val)
          expect(an_entry == equal).to be(true)

          # Same vertex, different origin
          diff_origin = described_class.new(sample_vertex, 2)
          expect(an_entry == diff_origin).to be(false)

          # Different vertices, same origin
          diff_vertex = described_class.new(double('other_sample_vertex'), 3)
          expect(an_entry == diff_vertex).to be(false)
        end

        it 'knows if the vertex is a start vertex' do
          expect(an_entry).to be_start_entry

          instance = described_class.new(GFG::EndVertex.new('.NT'), 3)
          expect(instance).not_to be_start_entry
        end

        it 'knows if the vertex is an end vertex' do
          expect(an_entry).not_to be_end_entry

          instance = described_class.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance).to be_end_entry
        end

        it 'knows if the entry is a dotted item vertex' do
          expect(an_entry).not_to be_dotted_entry

          instance = described_class.new(GFG::ItemVertex.new('P => S.'), 3)
          expect(instance).to be_dotted_entry
        end

        it 'knows if the vertex is at end of production (if any)' do
          # Case: start vertex
          instance1 = described_class.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance1).not_to be_exit_entry

          # Case: end vertex
          instance2 = described_class.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance2).not_to be_exit_entry

          # Case: item vertex not at end of rhs
          v1 = double('vertex-not-at-end')
          allow(v1).to receive(:complete?).and_return(false)
          instance3 = described_class.new(v1, 3)
          expect(instance3).not_to be_exit_entry

          # Case: item vertex at end of rhs
          v2 = double('vertex-at-end')
          allow(v2).to receive(:complete?).and_return(true)
          instance4 = described_class.new(v2, 3)
          expect(instance4).to be_exit_entry
        end

        it 'knows if the vertex is at begin of production (if any)' do
          # Case: start vertex
          instance1 = described_class.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance1).not_to be_entry_entry

          # Case: end vertex
          instance2 = described_class.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance2).not_to be_entry_entry

          # Case: item vertex not at begin of rhs
          d1 = Base::DottedItem.new(sample_prod, 1)
          v1 = GFG::ItemVertex.new(d1)
          instance3 = described_class.new(v1, 3)
          expect(instance3).not_to be_entry_entry

          # Case: item vertex at end of rhs
          d2 = Base::DottedItem.new(sample_prod, 0)
          v2 = GFG::ItemVertex.new(d2)
          instance4 = described_class.new(v2, 3)
          expect(instance4).to be_entry_entry
        end

        it 'knows the symbol before the dot (if any)' do
          # Case: start vertex
          instance1 = described_class.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance1.prev_symbol).to be_nil

          # Case: end vertex
          instance2 = described_class.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance2.prev_symbol).to be_nil # Really correct?

          # Case: item vertex not at start of rhs
          v1 = double('vertex-not-at-start')
          allow(v1).to receive(:prev_symbol).and_return('symbol')
          instance3 = described_class.new(v1, 3)
          expect(instance3.prev_symbol).to eq('symbol')

          # Case: item vertex at start of rhs
          v2 = double('vertex-at-start')
          allow(v2).to receive(:prev_symbol).and_return(nil)
          instance4 = described_class.new(v2, 0)
          expect(instance4.prev_symbol).to be_nil
        end

        it 'knows the next expected symbol (if any)' do
          # Case: start vertex
          instance1 = described_class.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance1.next_symbol).to be_nil

          # Case: end vertex
          instance2 = described_class.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance2.next_symbol).to be_nil

          # Case: item vertex not at end of rhs
          v1 = double('vertex-not-at-end')
          allow(v1).to receive(:next_symbol).and_return('symbol')
          instance3 = described_class.new(v1, 3)
          expect(instance3.next_symbol).to eq('symbol')

          # Case: item vertex at end of rhs
          v2 = double('vertex-at-end')
          allow(v2).to receive(:next_symbol).and_return(nil)
          instance4 = described_class.new(v2, 3)
          expect(instance4.next_symbol).to be_nil
        end

        it 'accepts antecedents' do
          antecedent = described_class.new(vertex2, origin_val)
          an_entry.add_antecedent(antecedent)
          expect(an_entry.antecedents).to eql([antecedent])
          expect(an_entry).not_to be_orphan
        end

        it 'knows its text representation' do
          expected = '.sentence | 3'
          expect(an_entry.to_s).to eq(expected)
        end

        it 'is be inspectable' do
          an_entry.add_antecedent(an_entry) # Cheat for the good cause...
          # expected = '.sentence | 3'
          prefix = /^#<Rley::Parser::ParseEntry:\d+ @vertex/
          expect(an_entry.inspect).to match(prefix)
          pattern = /@vertex=<Rley::GFG::StartVertex:\d+ label=\.sentence/
          expect(an_entry.inspect).to match(pattern)
          pattern2 = /@origin=3 @antecedents=\[/
          expect(an_entry.inspect).to match(pattern2)
          suffix = /<Rley::GFG::StartVertex:\d+ label=\.sentence> @origin=3\]>$/
          expect(an_entry.inspect).to match(suffix)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
