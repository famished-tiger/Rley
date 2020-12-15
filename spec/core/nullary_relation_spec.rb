# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/core/nullary_relation'


module MiniKraken
  module Core
    describe NullaryRelation do
      subject { NullaryRelation.new('fail') }

      context 'Initialization:' do
        it 'should be initialized with a name' do
          expect { NullaryRelation.new('fail') }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq('fail')
        end

        it 'should know its zero arity' do
          expect(subject.arity).to be_nullary
        end

        it 'should be frozen' do
          expect(subject).to be_frozen
        end
      end # context
    end # describe
  end # module
end # module
