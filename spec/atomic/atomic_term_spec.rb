# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require 'ostruct'

# Load the class under test
require_relative '../../lib/mini_kraken/atomic/atomic_term'

module MiniKraken
  module Atomic
    describe AtomicTerm do
      let(:a_value) { :serenity }
      let(:other_value) { :fuzziness }
      subject { AtomicTerm.new(a_value) }

      context 'Initialization:' do
        it 'should be created with a Ruby datatype instance' do
          expect { AtomicTerm.new(a_value) }.not_to raise_error
        end

        it 'knows its value' do
          expect(subject.value).to eq(a_value)
        end

        it 'freezes its value' do
          expect(subject.value).to be_frozen
        end
      end # context

      context 'Provided services:' do
        it 'should know that it is a pinned term' do
          ctx = double('mock-ctx')
          expect(subject.pinned?(ctx)).to be_truthy
        end

        it 'should know that it is not a floating term' do
          ctx = double('mock-ctx')
          expect(subject.floating?(ctx)).to be_falsy
        end

        it 'should know that it is not an unbound term' do
          ctx = double('mock-ctx')
          expect(subject.unbound?(ctx)).to be_falsy
        end

        it 'performs data value comparison' do
          expect(subject == subject).to be_truthy
          expect(subject == subject.value).to be_truthy

          expect(subject == other_value).to be_falsy
          expect(subject == AtomicTerm.new(other_value)).to be_falsy

          # Same duck type, same value
          yet_another = OpenStruct.new(value: a_value)
          expect(subject == yet_another).to be_truthy

          # Same duck type, different value
          still_another = OpenStruct.new(value: other_value)
          expect(subject == still_another).to be_falsy
        end

        it 'performs type and data value comparison' do
          expect(subject).to be_eql(subject)

          # Same type, same value
          other = AtomicTerm.new(a_value)
          expect(subject).to be_eql(other)

          # Same type, other value
          another = AtomicTerm.new(other_value)
          expect(subject).not_to be_eql(another)

          # Different type, same value
          yet_another = OpenStruct.new(value: other_value)
          expect(subject).not_to be_eql(yet_another)
        end

        it 'returns itself when receiving quote message' do
          ctx = double('mock-ctx')
          expect(subject.quote(ctx)).to eq(subject)
        end

        it 'should know it has no dependency on variable(s)' do
          ctx = double('mock-ctx')
          expect(subject.dependencies(ctx)).to be_empty
        end

        it 'should dup itself' do
          substitutions = double('fake-substitutions')
          duplicate = subject.dup_cond(substitutions)
          expect(duplicate).to eq(subject) # same value
          expect(duplicate).not_to be_equal(subject) # different object ids
        end
      end # context
    end # describe
  end # module
end # module
