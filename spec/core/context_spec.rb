# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../../lib/mini_kraken/core/association'
require_relative '../../lib/mini_kraken/core/log_var'
require_relative '../../lib/mini_kraken/composite/all_composite'

require_relative '../support/factory_atomic'
require_relative '../support/factory_methods'

# Load the class under test
require_relative '../../lib/mini_kraken/core/context'

module MiniKraken
  module Core
    describe Context do
      include MiniKraken::FactoryAtomic # Use mix-in module
      subject { Context.new }

      context 'Initialization:' do
        it 'should be initialized without argument' do
          expect { Context.new }.not_to raise_error
        end

        it 'should have an empty symbol table' do
          expect(subject.symbol_table).to be_empty
        end

        it 'should have an empty blackboard' do
          expect(subject.blackboard).to be_empty
        end
      end # context

      context 'Initialization:' do
        def var(aName)
          LogVar.new(aName)
        end

        it 'should accept the addition of an entry in symbol table' do
          subject.insert(var('x'))
          expect(subject.symbol_table).not_to be_empty
          expect(subject.symbol_table.current_scope.defns['x']).to be_kind_of(LogVar)
        end

        it 'should create one or more variables from name(s)' do
          # Case: single name
          subject.add_vars('x')
          expect(subject.symbol_table).not_to be_empty
          expect(subject.symbol_table.current_scope.defns['x']).to be_kind_of(LogVar)

          # Case: multiple names
          subject.add_vars(['y', 'z'])
          expect(subject.symbol_table.current_scope.defns['y']).to be_kind_of(LogVar)
          expect(subject.symbol_table.current_scope.defns['z']).to be_kind_of(LogVar)
        end

        it 'should accept the addition of an association to a given i_name' do
          i_name_x = subject.insert(var('x'))
          i_name_y = subject.insert(var('y'))

          expect(subject.associations_for('x')).to be_empty
          something = double('something')
          assoc_x = subject.associate('x', something)
          expect(subject.associations_for('x')).to eq([assoc_x])

          thing = double('thing')
          assoc_y = Association.new(i_name_y, thing)
          subject.enqueue_association(assoc_y)
          expect(subject.associations_for('y')).to eq([assoc_y])

          blob = double('blob')
          assoc2_x = Association.new(i_name_x, blob)
          subject.enqueue_association(assoc2_x)
          expect(subject.associations_for('x')).to eq([assoc_x, assoc2_x])

          var_y = subject.lookup('y')
          foo = double('bar')
          assoc2_y = subject.associate(var_y, foo)
          expect(subject.associations_for('y')).to eq([assoc_y, assoc2_y])
        end

        it 'should allow the fusion of two variables' do
          symb_tbl = subject.symbol_table
          i_name_q = subject.insert(var('q'))
          symb_tbl.enter_scope(Core::Scope.new)
          i_name_x = subject.insert(var('x'))

          expect(subject.associations_for('q')).to be_empty
          something = double('something')
          assoc_x = subject.associate('x', something)
          expect(subject.associations_for('x')).to eq([assoc_x])
          pre_queue_size = subject.blackboard.move_queue.size
          fusion = subject.fuse(['q', 'x'])

          expect(fusion).to be_kind_of(Fusion)
          expect(fusion.elements).to eq(['q', 'x'].map { |e| subject.lookup(e).i_name })
          expect(subject.blackboard.move_queue.size).to eq(pre_queue_size + 2)
          expect(subject.cv2vars).to be_include(fusion.i_name)
          expect(subject.cv2vars[fusion.i_name]).to eq(fusion.elements)
          expect(subject.blackboard.vars2cv[i_name_q]).to eq(fusion.i_name)
          expect(subject.blackboard.vars2cv[i_name_x]).to eq(fusion.i_name)
          expect(subject.associations_for('q')).not_to be_empty
        end

        it 'should allow the search of an entry based on its name' do
          symb_tbl = subject.symbol_table
          subject.add_vars(['q', 'x'])
          symb_tbl.enter_scope(Core::Scope.new)
          subject.add_vars(['q', 'y'])

          # Search for unknown name
          expect(subject.lookup('z')).to be_nil

          # Search for existing unique names
          expect(subject.lookup('y')).to eq(symb_tbl.current_scope.defns['y'])
          expect(subject.lookup('x')).to eq(symb_tbl.root.defns['x'])

          # Search for redefined name
          expect(subject.lookup('q')).to eq(symb_tbl.current_scope.defns['q'])
        end

        it 'should determine the ranks of fresh variables' do
          subject.add_vars(%w[x y z])

          ref_y = LogVarRef.new('y')
          assoc_x = subject.associate('x', ref_y)
          subject.send(:calc_ranking)
          expect(subject.ranking.size).to eq(2)
          i_name_y = subject.lookup('y').i_name
          expect(subject.ranking[i_name_y]).to eq(0)
          i_name_z = subject.lookup('z').i_name
          expect(subject.ranking[i_name_z]).to eq(1)
        end

        it 'should allow entering in a new scope' do
          new_scope = Scope.new
          expect { subject.enter_scope(new_scope) }.not_to raise_error
          expect(subject.symbol_table.current_scope).to eq(new_scope)
        end

        it 'should allow leaving out current scope' do
          subject.add_vars(%w[q x])
          x_val = k_symbol(:foo)
          assoc_x = subject.associate('x', x_val) # x => :foo
          expect(subject.blackboard.move_queue.size).to eq(1)
          new_scope = Scope.new
          subject.enter_scope(new_scope) # Adds one bookmark
          expect(subject.blackboard.move_queue.size).to eq(2)
          subject.add_vars(%w[w x y z])

          q_val = LogVarRef.new('x')
          assoc_q = subject.associate('q', q_val)
          w_val = k_symbol(:bar)
          subject.associate('w', w_val)
          x2_val = LogVarRef.new('z')
          assoc2_x = subject.associate('x', x2_val)
          y_val = k_symbol(:foobar)
          subject.associate('y', y_val)
          # x => :foo
          # ------
          # q => x
          # w => :bar
          # x => z
          # y => :foobar
          expect(subject.blackboard.i_name2moves.keys.size).to eq(5)
          expect(subject.blackboard.move_queue.size).to eq(6)
          # require 'debug'
          # expect { 
          subject.leave_scope #}.not_to raise_error
          # Expected state:
          # x => :foo
          # q => x'
          # x' => z
          expect(subject.blackboard.move_queue.size).to eq(3)
          symb_table = subject.symbol_table
          expect(symb_table.current_scope).to eq(symb_table.root)
          expect(subject.blackboard.i_name2moves.keys.size).to eq(3)
          expect(subject.blackboard.move_queue).to eq([assoc_x, assoc_q, assoc2_x])
        end

        it 'should substitute values of associations (if needed)' do
          subject.add_vars(%w[q x y z])

          x_ref = LogVarRef.new('x')
          foobar = Composite::ConsCell.new(k_symbol(:foo), k_symbol(:bar))
          q_val = Composite::ConsCell.new(x_ref, foobar)
          assoc_q = subject.associate('q', q_val)
          subject.send(:calc_ranking)

          expect(subject.send(:substitute, assoc_q).to_s).to eq('(_0 :foo . :bar)')
        end

        it 'should build a solution' do
          subject.add_vars(%w[x y z])

          subject.succeeded!
          sol = subject.build_solution
          expect(sol.size).to eq(3)
          expect(sol['x']).to eq(:_0)
          expect(sol['y']).to eq(:_1)
          expect(sol['z']).to eq(:_2)

          foo = k_symbol(:foo)
          assoc_x = subject.associate('x', foo)
          sol = subject.build_solution
          expect(sol.size).to eq(3)
          expect(sol['x']).to eq(foo)
          expect(sol['y']).to eq(:_0)
          expect(sol['z']).to eq(:_1)

          bar = k_symbol(:bar)
          assoc_y = subject.associate('y', bar)
          sol = subject.build_solution
          expect(sol.size).to eq(3)
          expect(sol['x']).to eq(foo)
          expect(sol['y']).to eq(bar)
          expect(sol['z']).to eq(:_0)
        end
      end
    end # describe
  end # module
end # module
