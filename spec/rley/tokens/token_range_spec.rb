require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/tokens/token_range'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Tokens # Open this namespace to avoid module qualifier prefixes
    describe TokenRange do
      let(:sample_range) { { low: 0, high: 5 } }

      # Default instantiation rule
      subject { TokenRange.new(sample_range) }

      context 'Initialization:' do
        it 'could be created with a range Hash' do
          # No bounds provided
          expect { TokenRange.new({}) }.not_to raise_error

          # Low bound provided
          expect { TokenRange.new(low: 0) }.not_to raise_error

          # High bound provided
          expect { TokenRange.new(high: 5) }.not_to raise_error

          # Both bounds provided
          expect { TokenRange.new(low: 0, high: 5) }.not_to raise_error
        end
        
        it 'could be created with another TokenRange' do
          # Low bound provided
          instance = TokenRange.new(low: 0)
          expect { TokenRange.new(instance) }.not_to raise_error

          # High bound provided
          instance = TokenRange.new(high: 5)
          expect { TokenRange.new(instance) }.not_to raise_error

          # Both bounds provided
          instance = TokenRange.new(low: 0, high: 5)
          expect { TokenRange.new(instance) }.not_to raise_error
        end

        it 'should know its low bound' do
          expect(subject.low).to eq(0)
        end

        it 'should know its low bound' do
          expect(subject.high).to eq(5)
        end
      end # context

      context 'Provided services:' do
        it 'should compare to another range' do
          me = subject
          expect(subject == me).to eq(true)
          equal = TokenRange.new(low: 0, high: 5)
          expect(subject == equal).to eq(true)
          # expect(subject == [0..5]).to eq(true)
          expect(subject == [0, 5]).to eq(true)
        end

      
        it 'should know whether it is bounded or not' do
          expect(subject).to be_bounded

          # Case: only low bound is set
          instance = TokenRange.new(low: 0)
          expect(instance).not_to be_bounded

          # Case: only upper bound is set
          instance = TokenRange.new(high: 5)
          expect(instance).not_to be_bounded

          # No bound is set
          instance = TokenRange.new({})
          expect(instance).not_to be_bounded
        end

        it 'should assign its open bounds' do
          some_range = { low: 1, high: 4 }

          ###########
          # Case of bounded token range...
          subject.assign(some_range)

          # ... should be unchanged
          expect(subject.low).to eq(sample_range[:low])
          expect(subject.high).to eq(sample_range[:high])

          ###########
          # Case: only low bound is set
          instance = TokenRange.new(low: 0)
          instance.assign(some_range)

          # Expectation: high is assigned the new value
          expect(instance).to be_bounded
          expect(instance.low).to eq(0)
          expect(instance.high).to eq(4)

          ###########
          # Case: only high bound is set
          instance = TokenRange.new(high: 5)
          instance.assign(some_range)

          # Expectation: low is assigned the new value
          expect(instance).to be_bounded
          expect(instance.low).to eq(1)
          expect(instance.high).to eq(5)

          ###########
          # Case: no bound is set
          instance = TokenRange.new({})
          instance.assign(some_range)

          # Expectation: low is assigned the new value
          expect(instance).to be_bounded
          expect(instance.low).to eq(1)
          expect(instance.high).to eq(4)
        end
        
        it 'should tell whether an index value lies outside the range' do
          # Out of range...
          expect(subject.out_of_range?(-1)).to eq(true)
          expect(subject.out_of_range?(6)).to eq(true)
          
          # On boundaries...
          expect(subject.out_of_range?(0)).to eq(false)
          expect(subject.out_of_range?(5)).to eq(false)
          
          # Inside boundaries
          expect(subject.out_of_range?(2)).to eq(false)

          instance = TokenRange.new(low: nil, high: 5)
          
          # Lower bound is nil
          expect(instance.out_of_range?(-1)).to eq(false)
          expect(instance.out_of_range?(5)).to eq(false)
          expect(instance.out_of_range?(6)).to eq(true)
          
          instance = TokenRange.new(low: 0, high: nil)
          
          # Upper bound is nil
          expect(instance.out_of_range?(-1)).to eq(true)
          expect(instance.out_of_range?(0)).to eq(false)
          expect(instance.out_of_range?(6)).to eq(false)
        end
        
        it 'should provide a text representation of itself' do
          # Case 1: not bound is set
          instance = TokenRange.new({})
          expect(instance.to_string(0)).to eq('[?, ?]') 
          
          # Case: only low bound is set
          instance = TokenRange.new(low: 0)
          expect(instance.to_string(0)).to eq('[0, ?]') 

          # Case: only upper bound is set
          instance = TokenRange.new(high: 5) 
          expect(instance.to_string(0)).to eq('[?, 5]') 

          # Case: both bounds are set
          instance = TokenRange.new(low: 0, high: 5) 
          expect(instance.to_string(0)).to eq('[0, 5]')            
        end
      end
    end # describe
  end # module
end # module

# End of file
