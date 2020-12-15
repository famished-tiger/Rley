# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/core/log_var'


module MiniKraken
  module Core
    describe LogVar do
      subject { LogVar.new('q') }

      context 'Initialization:' do
        it 'should be initialized with a name' do
          expect { LogVar.new('q') }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq('q')
        end        
        
        it 'should have a frozen label' do
          expect(subject.label).to be_frozen
        end
        
        it 'should know its default internal name' do
          # By default: internal name == label
          expect(subject.i_name).to eq(subject.label)
        end        
        
        it 'should have a nil suffix' do
          expect(subject.suffix).to be_nil
        end
      end # context
      
      context 'Provided service:' do
        let(:sample_suffix) { 'sample-suffix' }
        it 'should have a label equal to its user-defined name' do
          expect(subject.label).to eq(subject.name)
        end

        it 'should accept a suffix' do
          expect { subject.suffix = sample_suffix }.not_to raise_error
          expect(subject.suffix).to eq(sample_suffix)
        end
        
        it 'should calculate its internal name' do
          # Rule: empty suffix => internal name == label
          subject.suffix = ''
          expect(subject.i_name).to eq(subject.label)
          
          # Rule: suffix starting underscore: internal name = label + suffix
          subject.suffix = '_10'
          expect(subject.i_name).to eq(subject.label + subject.suffix) 

          # Rule: ... otherwise: internal name == suffix
          subject.suffix = sample_suffix
           expect(subject.i_name).to eq(subject.suffix)
        end
      end # context
    end # describe
  end # module
end # module
