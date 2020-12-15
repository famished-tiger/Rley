# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/relation'

# Load the class under test
require_relative '../../lib/mini_kraken/core/parametrized_term'

module MiniKraken
  module Core
    describe ParametrizedTerm do
      let(:specif) { Relation.new('disj2', 2) }
      let(:arg1) { Term.new }
      let(:arg2) { Term.new }
      let(:arg3) { Term.new }
      subject { ParametrizedTerm.new(specif, [arg1, arg2]) }

      context 'Initialization:' do
        it 'should be initialized with a specification and actuals' do
          expect { ParametrizedTerm.new(specif, [arg1, arg2]) }.not_to raise_error
        end

        it 'should fail when number of arguments out of arity range' do
          err = StandardError
          err_msg = 'Count of arguments (3) is out of allowed range (2, 2).'
          expect { ParametrizedTerm.new(specif, [arg1, arg2, arg3]) }.to raise_error(err, err_msg)
        end

        it 'should know its specification' do
          expect(subject.specification).to eq(specif)
        end

        it 'should know its actuals' do
          expect(subject.actuals).to eq([arg1, arg2])
        end
      end # context
    end # describe
  end # module
end # module
