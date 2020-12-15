# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require 'ostruct'

# Load the class under test
require_relative '../../lib/mini_kraken/atomic/k_boolean'

module MiniKraken
  module Atomic
    describe KBoolean do
      subject { KBoolean.new('#t') }

      context 'Initialization:' do
        it 'could be created with a Ruby true/false value' do
          expect { KBoolean.new(true) }.not_to raise_error
          expect { KBoolean.new(false) }.not_to raise_error
        end

        it 'could be created with a Ruby Symbol value' do
          expect { KBoolean.new(:"#t") }.not_to raise_error
          expect { KBoolean.new(:"#f") }.not_to raise_error
        end

        it 'could be created with a Ruby String value' do
          expect { KBoolean.new('#t') }.not_to raise_error
          expect { KBoolean.new('#f') }.not_to raise_error
        end

        it 'should know its value' do
          other = KBoolean.new(true)
          expect(other.value).to eq(true)

          other = KBoolean.new('#t')
          expect(other.value).to eq(true)

          other = KBoolean.new(:"#t")
          expect(other.value).to eq(true)

          other = KBoolean.new(false)
          expect(other.value).to eq(false)

          other = KBoolean.new('#f')
          expect(other.value).to eq(false)

          other = KBoolean.new(:"#f")
          expect(other.value).to eq(false)
        end
      end # context

      context 'Provided services:' do
        it 'should know whether it is equal to another instance' do
          # Same type, same value
          other = KBoolean.new(true)
          expect(subject).to be_eql(other)

          # Same type, other value
          another = KBoolean.new(false)
          expect(subject).not_to be_eql(another)

          # Same type, other value
          another = KBoolean.new('#f')
          expect(subject).not_to be_eql(another)
        end

        it 'should know whether it has same value than other object' do
          # Same type, same value
          other = KBoolean.new(true)
          expect(subject == other).to be_truthy

          # Same type, other value
          another = KBoolean.new(false)
          expect(subject == another).to be_falsy

          # Same duck type, same value
          yet_another = OpenStruct.new(value: true)
          expect(subject == yet_another).to be_truthy

          # Same duck type, different value
          still_another = OpenStruct.new(value: false)
          expect(subject == still_another).to be_falsy

          # Default Ruby representation, same value
          expect(subject == true).to be_truthy

          # Default Ruby representation, different value
          expect(subject == false).to be_falsy
        end

        it 'provides a text representation of itself' do
          expect(subject.to_s).to eq('true')
          other = KBoolean.new('#f')
          expect(other.to_s).to eq('false')
        end
      end # context
    end # describe
  end # module
end # module
