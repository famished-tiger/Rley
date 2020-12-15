# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/log_var'

# Load the class under test
require_relative '../../lib/mini_kraken/core/symbol_table'

module MiniKraken
  module Core
    describe SymbolTable do
      subject { SymbolTable.new }

      context 'Initialization:' do
        it 'should be initialized without argument' do
          expect { SymbolTable.new }.not_to raise_error
        end

        it 'should have a root scope' do
          expect(subject.root).not_to be_nil
          expect(subject.current_scope).to eq(subject.root)
          expect(subject.root).to be_kind_of(Core::Scope)
        end

        it "shouldn't have names at initialization" do
          expect(subject.name2scopes).to be_empty
        end

        it 'should be empty at initialization' do
          expect(subject).to be_empty
        end
      end # context

      context 'Provided services:' do
        def var(aName)
          LogVar.new(aName)
        end

        it 'should allow the addition of a variable' do
          expect { subject.insert(var('q')) }.not_to raise_error
          expect(subject).not_to be_empty
          expect(subject.name2scopes['q']).to be_kind_of(Array)
          expect(subject.name2scopes['q'].size).to eq(1)
          expect(subject.name2scopes['q'].first).to eq(subject.current_scope)
          expect(subject.current_scope.defns['q']).to be_kind_of(Core::LogVar)
        end

        it 'should allow the addition of several labels for same env' do
          i_name = subject.insert(var('q'))
          expect(i_name).to match /^q_[0-9a-z]+$/

          expect { subject.insert(var('x')) }.not_to raise_error
          expect(subject.name2scopes['x']).to be_kind_of(Array)
          expect(subject.name2scopes['x'].first).to eq(subject.current_scope)
          expect(subject.current_scope.defns['x']).to be_kind_of(Core::LogVar)
        end

        it 'should allow the entry into a new scope' do
          subject.insert(var('q'))
          new_scope = Core::Scope.new
          expect { subject.enter_scope(new_scope) }.not_to raise_error
          expect(subject.current_scope).to eq(new_scope)
          expect(subject.current_scope.parent).to eq(subject.root)
          expect(subject.name2scopes['q']).to eq([subject.root])

        end

        it 'should allow the addition of same name in different scopes' do
          subject.insert(var('q'))
          subject.enter_scope(Core::Scope.new)
          subject.insert(var('q'))
          expect(subject.name2scopes['q']).to be_kind_of(Array)
          expect(subject.name2scopes['q'].size).to eq(2)
          expect(subject.name2scopes['q'].first).to eq(subject.root)
          expect(subject.name2scopes['q'].last).to eq(subject.current_scope)
          expect(subject.current_scope.defns['q']).to be_kind_of(Core::LogVar)
        end

        it 'should allow the removal of a scope' do
          subject.insert(var('q'))
          new_scope = Core::Scope.new
          subject.enter_scope(new_scope)
          subject.insert(var('q'))
          expect(subject.name2scopes['q'].size).to eq(2)

          expect { subject.leave_scope }.not_to raise_error
          expect(subject.current_scope).to eq(subject.root)
          expect(subject.name2scopes['q'].size).to eq(1)
          expect(subject.name2scopes['q']).to eq([subject.root])
        end

        it 'should allow the search of an entry based on its name' do
          subject.insert(var('q'))
          subject.insert(var('x'))
          subject.enter_scope(Core::Scope.new)
          subject.insert(var('q'))
          subject.insert(var('y'))

          # Search for unknown name
          expect(subject.lookup('z')).to be_nil

          # Search for existing unique names
          expect(subject.lookup('y')).to eq(subject.current_scope.defns['y'])
          expect(subject.lookup('x')).to eq(subject.root.defns['x'])

          # Search for redefined name
          expect(subject.lookup('q')).to eq(subject.current_scope.defns['q'])
        end

        it 'should allow the search of an entry based on its i_name' do
          subject.insert(var('q'))
          i_name_x = subject.insert(var('x'))
          subject.enter_scope(Core::Scope.new)
          i_name_q2 = subject.insert(var('q'))
          i_name_y = subject.insert(var('y'))

          # Search for unknown i_name
          expect(subject.lookup_i_name('dummy')).to be_nil

          curr_scope = subject.current_scope
          # # Search for existing unique names
          expect(subject.lookup_i_name(i_name_y)).to eq(curr_scope.defns['y'])
          expect(subject.lookup_i_name(i_name_x)).to eq(subject.root.defns['x'])

          # Search for redefined name
          expect(subject.lookup_i_name(i_name_q2)).to eq(curr_scope.defns['q'])
        end
        
        it 'should list all the variables defined in all the szcope chain' do
          subject.insert(var('q'))
          subject.enter_scope(Core::Scope.new)
          subject.insert(var('x'))
          subject.enter_scope(Core::Scope.new)          
          subject.insert(var('y'))
          subject.insert(var('x'))          
          
          vars = subject.all_variables
          expect(vars.map(&:name)).to eq(%w[q x y x])
        end
      end # context
    end # describe
  end # module
end # module
