require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'

# Load the class under test
require_relative '../../../lib/rley/parser/dotted_item'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes

  describe DottedItem do
    let(:t_a) { Syntax::Terminal.new('A') }
    let(:t_b) { Syntax::Terminal.new('B') }
    let(:t_c) { Syntax::Terminal.new('C') }
    let(:nt_sentence) { Syntax::NonTerminal.new('sentence') }

    let(:sample_prod) do
      Syntax::Production.new(nt_sentence, [t_a, t_b, t_c])
    end

    let(:other_prod) do
      Syntax::Production.new(nt_sentence, [t_a])
    end
    
    let(:empty_prod) do
      Syntax::Production.new(nt_sentence,[])
    end


    subject { DottedItem.new(sample_prod, 1) }

    context 'Initialization:' do
      it 'should be created with a production and an index' do
        expect { DottedItem.new(sample_prod, 0) }.not_to raise_error
        expect { DottedItem.new(sample_prod, 3) }.not_to raise_error
      end

      it 'should complain when the index is out-of-bounds' do
        err = StandardError
        msg = 'Out of bound index'
        expect { DottedItem.new(sample_prod, 4) }.to raise_error(err, msg)
      end

      it 'should know its production' do
        expect(subject.production).to eq(sample_prod)
      end

      it 'should know its position' do
        # At start position
        instance1 = DottedItem.new(sample_prod, 0)
        expect(instance1.position).to eq(0)

        # At (before) last symbol
        instance2 = DottedItem.new(sample_prod, 2)
        expect(instance2.position).to eq(2)

        # After all symbols in rhs
        instance3 = DottedItem.new(sample_prod, 3)
        expect(instance3.position).to eq(-1)

        # At start/end at the same time (production is empty)
        instance4 = DottedItem.new(Syntax::Production.new(nt_sentence, []), 0)
        expect(instance4.position).to eq(-2)
      end

    end # context

    context 'Provided service:' do
      it 'should whether it is a reduce item' do
        expect(subject).not_to be_reduce_item

        first_instance = DottedItem.new(sample_prod, 3)
        expect(first_instance).to be_reduce_item

        second_instance = DottedItem.new(empty_prod, 0)
        expect(second_instance).to be_reduce_item        
      end
      
      it 'should know the symbol after the dot' do
        expect(subject.next_symbol).to eq(t_b)
      end
    end

  end # describe

  end # module
end # module

# End of file

