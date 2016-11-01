require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/dotted_item'

# Load the class under test
require_relative '../../../lib/rley/parser/parse_entry'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe ParseEntry do
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

      let(:dotted_rule) { DottedItem.new(sample_prod, 2) }
      let(:origin_val) { 3 }
      let(:vertex_faked) { double('fake-vertex') }
      let(:vertex2) { double('vertex-mock') }
      # Default instantiation rule
      subject { ParseEntry.new(vertex_faked, origin_val) }

      context 'Initialization:' do
        it 'should be created with a vertex and an origin position' do
          args = [vertex_faked, origin_val]
          expect { ParseEntry.new(*args) }.not_to raise_error
        end

        it 'should complain when the vertex is nil' do
          err = StandardError
          msg = 'GFG vertex cannot be nil'
          expect { ParseEntry.new(nil, 2) }.to raise_error(err, msg)
        end

        it 'should know the vertex' do
          expect(subject.vertex).to eq(vertex_faked)
        end

        it 'should know the origin value' do
          expect(subject.origin).to eq(origin_val)
        end
        
        it 'should have not antecedent at creation' do
          expect(subject.antecedents).to be_empty
          expect(subject).to be_orphan
        end
      end # context

      context 'Provided services:' do
        it 'should compare with itself' do
          synonym = subject # Fool Rubocop
          expect(subject == synonym).to eq(true)
        end

        it 'should compare with another' do
          equal = ParseEntry.new(vertex_faked, origin_val)
          expect(subject == equal).to eq(true)

          # Same vertex, different origin
          diff_origin = ParseEntry.new(vertex_faked, 2)
          expect(subject == diff_origin).to eq(false)

          # Different vertices, same origin
          diff_vertex = ParseEntry.new(double('other_vertex_faked'), 3)
          expect(subject == diff_vertex).to eq(false)
        end

        it 'should know if the vertex is a start vertex' do
          expect(subject).not_to be_start_entry

          instance = ParseEntry.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance).to be_start_entry
        end

        it 'should know if the vertex is an end vertex' do
          expect(subject).not_to be_end_entry

          instance = ParseEntry.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance).to be_end_entry
        end
        
        it 'should know if the entry is a dotted item vertex' do
          expect(subject).not_to be_dotted_entry

          instance = ParseEntry.new(GFG::ItemVertex.new('P => S.'), 3)
          expect(instance).to be_dotted_entry
        end             

        it 'should know if the vertex is at end of production (if any)' do
          # Case: start vertex
          instance1 = ParseEntry.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance1).not_to be_exit_entry

          # Case: end vertex
          instance2 = ParseEntry.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance2).not_to be_exit_entry

          # Case: item vertex not at end of rhs
          v1 = double('vertex-not-at-end')
          expect(v1).to receive(:complete?).and_return(false)
          instance3 = ParseEntry.new(v1, 3)
          expect(instance3).not_to be_exit_entry

          # Case: item vertex at end of rhs
          v2 = double('vertex-at-end')
          expect(v2).to receive(:complete?).and_return(true)
          instance4 = ParseEntry.new(v2, 3)
          expect(instance4).to be_exit_entry
        end
        
        it 'should know if the vertex is at begin of production (if any)' do
          # Case: start vertex
          instance1 = ParseEntry.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance1).not_to be_entry_entry

          # Case: end vertex
          instance2 = ParseEntry.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance2).not_to be_entry_entry

          # Case: item vertex not at begin of rhs
          d1 = DottedItem.new(sample_prod, 1)          
          v1 = GFG::ItemVertex.new(d1)
          instance3 = ParseEntry.new(v1, 3)
          expect(instance3).not_to be_entry_entry

          # Case: item vertex at end of rhs
          d2 = DottedItem.new(sample_prod, 0)          
          v2 = GFG::ItemVertex.new(d2)          
          instance4 = ParseEntry.new(v2, 3)
          expect(instance4).to be_entry_entry
        end 

        it 'should know the symbol before the dot (if any)' do
          # Case: start vertex
          instance1 = ParseEntry.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance1.prev_symbol).to be_nil

          # Case: end vertex
          instance2 = ParseEntry.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance2.prev_symbol).to be_nil # Really correct?
          
          # Case: item vertex not at start of rhs
          v1 = double('vertex-not-at-start')
          expect(v1).to receive(:prev_symbol).and_return('symbol')
          instance3 = ParseEntry.new(v1, 3)
          expect(instance3.prev_symbol).to eq('symbol') 

          # Case: item vertex at start of rhs
          v2 = double('vertex-at-start')
          expect(v2).to receive(:prev_symbol).and_return(nil)
          instance4 = ParseEntry.new(v2, 0)
          expect(instance4.prev_symbol).to be_nil          
        end
        
        it 'should know the next expected symbol (if any)' do
          # Case: start vertex
          instance1 = ParseEntry.new(GFG::StartVertex.new('.NT'), 3)
          expect(instance1.next_symbol).to be_nil

          # Case: end vertex
          instance2 = ParseEntry.new(GFG::EndVertex.new('NT.'), 3)
          expect(instance2.next_symbol).to be_nil
          
          # Case: item vertex not at end of rhs
          v1 = double('vertex-not-at-end')
          expect(v1).to receive(:next_symbol).and_return('symbol')
          instance3 = ParseEntry.new(v1, 3)
          expect(instance3.next_symbol).to eq('symbol') 

          # Case: item vertex at end of rhs
          v2 = double('vertex-at-end')
          expect(v2).to receive(:next_symbol).and_return(nil)
          instance4 = ParseEntry.new(v2, 3)
          expect(instance4.next_symbol).to be_nil          
        end  

        it 'should accept antecedents' do
          antecedent = ParseEntry.new(vertex2, origin_val)
          subject.add_antecedent(antecedent)
          expect(subject.antecedents).to eql([antecedent])
          expect(subject).not_to be_orphan
        end
=begin

        it 'should know its text representation' do
          expected = 'sentence => A B . C | 3'
          expect(subject.to_s).to eq(expected)
        end
=end
      end # context
    end # describe
  end # module
end # module

# End of file
