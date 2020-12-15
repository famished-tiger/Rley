# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../support/factory_atomic'

# Load the class under test
require_relative '../../lib/mini_kraken/core/scope'

module MiniKraken
  module Core
    describe Scope do
      include MiniKraken::FactoryAtomic # Use mix-in module
      let(:mother) { Scope.new }
      subject { Scope.new(mother) }
      
      def var(aName)
        LogVar.new(aName)
      end

      context 'Initialization:' do
        it 'could be initialized without argument' do
          expect { Scope.new }.not_to raise_error
        end
        
        it 'could be initialized with a parent scope' do
          expect { Scope.new(mother) }.not_to raise_error
        end        

        it "shouldn't have definitions by default" do
          expect(subject.defns).to be_empty
        end
        
        it 'should know its parent (if any)' do
          expect(subject.parent).to eq(mother)
        end
      end # context

      context 'Provided services:' do
        it 'should accept the addition of a variable' do
          subject.insert(var('a'))
          expect(subject.defns).not_to be_empty
          var_a = subject.defns['a']
          expect(var_a).to be_kind_of(Core::LogVar)
          expect(var_a.label).to eq('a')
        end

        it 'should accept the addition of multiple variables' do
          subject.insert(var('a'))
          expect(subject.defns).not_to be_empty

          subject.insert(var('b'))
          var_b = subject.defns['b']
          expect(var_b).to be_kind_of(Core::LogVar)
          expect(var_b.label).to eq('b')
        end

        it 'should set the suffix of just created variable' do
          subject.insert(var('a'))
          var_a = subject.defns['a']
          expect(var_a.suffix).to eq("_#{subject.object_id.to_s(16)}")
        end

        it 'should complain when variable names collide' do
          subject.insert(var('c'))
          expect(subject.defns['c']).to be_kind_of(Core::LogVar)
          err = StandardError
          err_msg = "Variable with name 'c' already exists."
          expect{ subject.insert(var('c'))}.to raise_error(err, err_msg)
        end
      end # context
    end # describe
  end # module
end # module
