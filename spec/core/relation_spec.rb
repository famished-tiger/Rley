# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/core/relation'


module MiniKraken
  module Core
    describe Relation do
      subject { Relation.new('caro', 2) }

      context 'Initialization:' do
        it 'should be initialized with a name and an arity' do
          expect { Relation.new('caro', Arity.new(2, 2)) }.not_to raise_error
        end
        
        it 'should be initialized with a name and an integer' do
          expect { Relation.new('caro', 2) }.not_to raise_error
        end        

        it 'should know its name' do
          expect(subject.name).to eq('caro')
        end

        it 'should know its arity' do
          expect(subject.arity).to eq(Arity.new(2, 2))
        end
      end # context
    end # describe
  end # module
end # module
