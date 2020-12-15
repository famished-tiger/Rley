# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/core/specification'


module MiniKraken
  module Core
    describe Specification do
      subject { Specification.new('cons', 2) }

      context 'Initialization:' do
        it 'should be initialized with a name and an arity' do
          expect { Specification.new('cons', Arity.new(2, 2)) }.not_to raise_error
        end

        it 'should be initialized with a name and an integer' do
          expect { Specification.new('cons', 2) }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq('cons')
        end

        it 'should know its arity' do
          expect(subject.arity).to be_binary
        end
      end # context

      context 'Provided services:' do
        it "should complain when number of arguments does't fit arity" do
          dummy_arg = double('dummy-stuff')

          err = StandardError
          err_msg = 'Count of arguments (1) is out of allowed range (2, 2).'
          expect { subject.check_arity([dummy_arg]) }.to raise_error(err, err_msg)
        end
      end
    end # describe
  end # module
end # module
