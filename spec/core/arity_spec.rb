# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/core/arity'

module MiniKraken
  module Core
    describe Arity do
      subject { Arity.new(0, 1) }

      context 'Initialization:' do
        it 'should be initialized with two integers' do
          expect { Arity.new(0, 1) }.not_to raise_error
        end

        it 'should know its lower bound' do
          expect(subject.low).to eq(0)
        end

        it 'should know its upper bound' do
          expect(subject.high).to eq(1)
        end
      end # context

      context 'Initialization:' do
        it 'should know whether is is nullary' do
          expect(subject).not_to be_nullary

          instance = Arity.new(0, '*')
          expect(instance).not_to be_nullary

          instance = Arity.new(0, 0)
          expect(instance).to be_nullary
        end

        it 'should know whether is is unary' do
          expect(subject).not_to be_unary

          instance = Arity.new(1, 2)
          expect(instance).not_to be_unary

          instance = Arity.new(1, 1)
          expect(instance).to be_unary
        end

        it 'should know whether is is binary' do
          expect(subject).not_to be_binary

          instance = Arity.new(1, 2)
          expect(instance).not_to be_binary

          instance = Arity.new(2, 2)
          expect(instance).to be_binary
        end

        it 'should know whether is is variadic' do
          expect(subject).not_to be_variadic

          instance = Arity.new(1, '*')
          expect(instance).to be_variadic
        end

        it 'should know whether an integer fits the arity range' do
          expect(subject.match?(0)).to be_truthy
          expect(subject.match?(1)).to be_truthy
          expect(subject.match?(2)).to be_falsey

          instance = Arity.new(2, '*')
          expect(instance.match?(1)).to be_falsey
          expect(instance.match?(2)).to be_truthy
          expect(instance.match?(42)).to be_truthy
        end

        it 'should know whether is equal to another arity' do
          expect(subject == subject).to be_truthy

          same = Arity.new(0, 1)
          expect(subject == same).to be_truthy

          same_low = Arity.new(0, 2)
          expect(subject == same_low).to be_falsey

          same_high = Arity.new(1, 1)
          expect(subject == same_high).to be_falsey
        end
      end # context
    end # describe
  end # module
end # module
