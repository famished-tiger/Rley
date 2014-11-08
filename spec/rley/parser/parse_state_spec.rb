require_relative '../../spec_helper'


# Load the class under test
require_relative '../../../lib/rley/parser/parse_state'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes

  describe ParseState do

    let(:origin_value) { 3 }
    let(:dotted_rule) { double('fake-dotted-item') }
    let(:other_dotted_rule) { double('mock-dotted-item') }

    # Default instantiation rule
    subject { ParseState.new(dotted_rule, origin_value) }

    context 'Initialization:' do

      it 'should be created with a lexeme and a terminal argument' do
        expect { ParseState.new(dotted_rule, origin_value) }.not_to raise_error
      end

      it 'should know the related dotted rule' do
        expect(subject.dotted_rule).to eq(dotted_rule)
      end

      it 'should know the origin value' do
        expect(subject.origin).to eq(origin_value)
      end


    end # context

    context 'Provided services:' do
      it 'should compare with itself' do
        expect(subject == subject).to eq(true)
      end

      it 'should compare with another' do
        equal = ParseState.new(dotted_rule, origin_value)
        expect(subject == equal).to eq(true)

        # Same dotted_rule, different origin
        diff_origin = ParseState.new(dotted_rule, 2)
        expect(subject == diff_origin).to eq(false)

        # Different dotted item, same origin
        diff_rule = ParseState.new(other_dotted_rule, 3)
        expect(subject == diff_rule).to eq(false)
      end
    end # context

  end # describe

  end # module
end # module

# End of file