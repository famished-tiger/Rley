# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework
require_relative '../support/factory_atomic'
require_relative '../../lib/mini_kraken/core/log_var_ref'
require_relative '../../lib/mini_kraken/core/scope'
require_relative '../../lib/mini_kraken/composite/cons_cell'

# Load the class under test
require_relative '../../lib/mini_kraken/core/blackboard'

module MiniKraken
  module Core
    describe Blackboard do
      include MiniKraken::FactoryAtomic # Use mix-in module
      subject { Blackboard.new }

      context 'Initialization:' do
        it 'should be initialized without argument' do
          expect { Blackboard.new }.not_to raise_error
        end

        it "shouldn't have internal name entry at initialization" do
          expect(subject.i_name2moves).to be_empty
        end

        it 'should have an empty association queue at initialization' do
          expect(subject.move_queue).to be_empty
        end

        it 'should be empty at initialization' do
          expect(subject).to be_empty
        end

        it 'should be ready to assign a serial number' do
          expect(subject.next_serial_num).to be_zero
        end

        it 'should have its resultant attribute un-initialized' do
          expect(subject.resultant).to be_nil
        end
      end # context

      context 'Provided services:' do
        let(:a_ser_num) { 42 }
        let(:pea) { k_symbol(:pea) }
        let(:pod) { k_symbol(:pod) }
        let(:x_assoc) { Core::Association.new('x', pea) }
        let(:y_assoc) { Core::Association.new('y', pod) }
        let(:z_assoc) { Core::Association.new('z', pea) }

        def var_ref(aName)
          LogVarRef.new(aName)
        end

        def cons(car, cdr = nil)
          Composite::ConsCell.new(car, cdr)
        end

        it 'should allow the enqueuing of one association' do
          expect { subject.enqueue_association(x_assoc) }.not_to raise_error
          expect(subject.i_name2moves).not_to be_empty
          expect(subject.move_queue).not_to be_empty
          expect(subject.i_name2moves['x']).to be_kind_of(Array)
          expect(subject.i_name2moves['x'].first).to eq(0)
          expect(subject.last_move).to eq(x_assoc)
        end

        it 'should allow the enqueuing of multiple associations' do
          expect(subject.enqueue_association(x_assoc)).to eq(x_assoc)
          expect { subject.enqueue_association(y_assoc) }.not_to raise_error
          expect(subject.i_name2moves.size).to eq(2)
          expect(subject.move_queue.size).to eq(2)
          expect(subject.i_name2moves['y']).to be_kind_of(Array)
          expect(subject.i_name2moves['y'].first).to eq(1)
          expect(subject.last_move).to eq(y_assoc)
        end

        it 'should allow the enqueuing of multiple associations for same i_name' do
          subject.enqueue_association(x_assoc)

          x_assoc_b = Core::Association.new('x', double('something'))
          expect { subject.enqueue_association(x_assoc_b) }.not_to raise_error
          expect(subject.i_name2moves.size).to eq(1)
          expect(subject.move_queue.size).to eq(2)
          expect(subject.i_name2moves['x']).to be_kind_of(Array)
          expect(subject.i_name2moves['x'].size).to eq(2)
          expect(subject.i_name2moves['x'].last).to eq(1)
          expect(subject.move_queue.pop).to eq(x_assoc_b)
        end

        it 'should allow the removal of the association at TOS position' do
          subject.enqueue_association(x_assoc)
          x_assoc_b = Core::Association.new('x', double('something'))
          subject.enqueue_association(x_assoc_b)
          expect(subject.move_queue.size).to eq(2)
          expect(subject.i_name2moves.size).to eq(1)

          expect { subject.send(:dequeue_item) }.not_to raise_error
          expect(subject.move_queue.size).to eq(1)
          expect(subject.i_name2moves.size).to eq(1)

          subject.send(:dequeue_item)
          expect(subject.move_queue).to be_empty
          expect(subject.i_name2moves).to be_empty
        end

        it 'should allow the enqueuing of a backtrack bookmark' do
          subject.enqueue_association(x_assoc)

          expect { subject.place_bt_point }.not_to raise_error
          expect(subject.i_name2moves.size).to eq(1)
          expect(subject.move_queue.size).to eq(2)
          expect(subject.i_name2moves['x']).to be_kind_of(Array)
          expect(subject.i_name2moves['x'].size).to eq(1)
          expect(subject.last_move).to be_kind_of(Bookmark)
        end

        it 'should allow the enqueuing of a scope bookmark' do
          subject.enqueue_association(x_assoc)

          expect { subject.enter_scope }.not_to raise_error
          expect(subject.i_name2moves.size).to eq(1)
          expect(subject.move_queue.size).to eq(2)
          expect(subject.i_name2moves['x']).to be_kind_of(Array)
          expect(subject.i_name2moves['x'].size).to eq(1)
          expect(subject.last_move).to be_kind_of(Bookmark)
        end

        it 'should allow the fusion of two unbound variables' do
          q_var = LogVar.new('q')
          x_var = LogVar.new('x')
          q_x_var = LogVar.new('q_x')
          fusion = Fusion.new(q_x_var.i_name, [q_var.i_name, x_var.i_name])
          pre_size = subject.move_queue.size
          subject.enqueue_fusion(fusion)

          expect(subject.move_queue.size).to eq(pre_size + 1)
          expect(subject.i_name2moves).to be_include(q_x_var.i_name)
          expect(subject.vars2cv[q_var.i_name]).to eq(q_x_var.i_name)
          expect(subject.vars2cv[x_var.i_name]).to eq(q_x_var.i_name)
        end

        it 'should allow the fusion of one unbound and one floating variable' do
          q_var = LogVar.new('q')
          x_var = LogVar.new('x')
          assoc_x = Association.new('x', cons(LogVarRef.new('y'), pea))
          subject.enqueue_association(assoc_x)
          q_x_var = LogVar.new('q_x')
          fusion = Fusion.new(q_x_var.i_name, [q_var.i_name, x_var.i_name])
          pre_size = subject.move_queue.size

          subject.enqueue_fusion(fusion)
          expect(subject.move_queue.size).to eq(pre_size + 2)
          expect(subject.i_name2moves).to be_include(q_x_var.i_name)
          indices = subject.i_name2moves[q_x_var.i_name]
          expect(indices.size).to eq(2) # 2 = 1 Fusion + 1 AssocCopy
          new_assoc = subject.move_queue[indices.last]
          expect(new_assoc.value).to eq(assoc_x.value)
        end

        it 'should allow the fusion of two floating variables' do
          q_var = LogVar.new('q')
          x_var = LogVar.new('x')
          assoc_q = Association.new('x', cons(pod, var_ref('z')))
          subject.enqueue_association(assoc_q)
          assoc_x = Association.new('x', cons(var_ref('y'), pea))
          subject.enqueue_association(assoc_x)
          q_x_var = LogVar.new('q_x')
          fusion = Fusion.new(q_x_var.i_name, [q_var.i_name, x_var.i_name])
          pre_size = subject.move_queue.size

          subject.enqueue_fusion(fusion)
          expect(subject.move_queue.size).to eq(pre_size + 3)
          expect(subject.i_name2moves).to be_include(q_x_var.i_name)
          indices = subject.i_name2moves[q_x_var.i_name]
          expect(indices.size).to eq(3)
          new_move1 = subject.move_queue[indices[0]]
          expect(new_move1).to be_kind_of(Core::Fusion)
          new_move2 = subject.move_queue[indices[1]]
          expect(new_move2.value).to eq(assoc_q.value)
          new_move3 = subject.move_queue[indices[2]]
          expect(new_move3.value).to eq(assoc_x.value)
        end

        it 'should allow the removal of a fusion object at TOS position' do
          q_var = LogVar.new('q')
          x_var = LogVar.new('x')
          q_x_var = LogVar.new('q_x')
          fusion = Fusion.new(q_x_var.i_name, [q_var.i_name, x_var.i_name])
          pre_size = subject.move_queue.size
          subject.enqueue_fusion(fusion)

          expect(subject.move_queue.size).to eq(pre_size + 1)
          expect(subject.i_name2moves).to be_include(q_x_var.i_name)
          expect(subject.vars2cv[q_var.i_name]).to eq(q_x_var.i_name)
          expect(subject.vars2cv[x_var.i_name]).to eq(q_x_var.i_name)

          expect { subject.send(:dequeue_item) }.not_to raise_error
          expect(subject.move_queue.size).to eq(pre_size)
          expect(subject.i_name2moves).not_to be_include(q_x_var.i_name)
          expect(subject.vars2cv[q_var.i_name]).to be_nil
          expect(subject.vars2cv[x_var.i_name]).to be_nil
        end

        it 'should retrieve association for a given i_name (0 fusion)' do
          subject.enqueue_association(x_assoc)
          subject.enqueue_association(y_assoc)

          x_assoc_b = Core::Association.new('x', double('something'))
          subject.enqueue_association(x_assoc_b)
          expect(subject.associations_for('z')).to be_empty
          expect(subject.associations_for('y').size).to eq(1)
          expect(subject.associations_for('x').size).to eq(2)
          expect(subject.associations_for('x').last).to eq(x_assoc_b)
        end

        it 'should retrieve association for a given i_name (1 fusion)' do
          subject.enqueue_association(x_assoc)
          expect(subject.associations_for('x').size).to eq(1)
          expect(subject.associations_for('z').size).to eq(0)
          expect(subject.associations_for('z', true).size).to eq(0)

          x_z_var = LogVar.new('x_z')
          fusion = Fusion.new(x_z_var.i_name, %w[x z])
          subject.enqueue_fusion(fusion)
          expect(subject.associations_for('z', true).size).to eq(1)
          x_z_assoc = Core::Association.new(x_z_var.i_name, var_ref('y'))
          subject.enqueue_association(x_z_assoc)
          expect(subject.associations_for('z', false).size).to eq(0)
          expect(subject.associations_for('z', true).size).to eq(2)
          expect(subject.associations_for('x', false).size).to eq(1)
          expect(subject.associations_for('x', true).size).to eq(2)
        end

        it 'should accept the succeeded notification' do
          subject.enqueue_association(x_assoc)
          subject.enqueue_association(y_assoc)
          subject.succeeded!
          expect(subject).to be_success
          expect(subject.move_queue.size).to eq(2)
        end

        it 'should accept the failed notification in absence of bookmarks' do
          subject.enqueue_association(x_assoc)
          subject.enqueue_association(y_assoc)
          subject.failed!
          expect(subject).to be_failure
          expect(subject.move_queue).to be_empty
          expect(subject.i_name2moves).to be_empty
        end

        it 'should accept the failed notification with backtrack' do
          x_assoc2 = Core::Association.new('x', pea)

          subject.enqueue_association(x_assoc)
          subject.enqueue_association(y_assoc)
          subject.place_bt_point
          subject.enqueue_association(z_assoc)
          subject.enqueue_association(x_assoc2)
          expect(subject.i_name2moves['x'].size).to eq(2)

          subject.failed!
          expect(subject.resultant).to eq(:"#u")
          expect(subject.last_move).to be_kind_of(Core::Bookmark)
          expect(subject.i_name2moves.include?('z')).to be_falsey
          expect(subject.i_name2moves['x'].size).to eq(1)
        end

        it 'should accept the failed notification on a bookmark' do
          subject.enqueue_association(x_assoc)
          subject.enqueue_association(y_assoc)
          subject.place_bt_point # Backtrack point bookmark added...

          subject.enqueue_association(z_assoc)
          subject.enter_scope # Scope bookmark

          expect(subject.move_queue.size).to eq(5)

          subject.failed!
          expect(subject.resultant).to eq(:"#u")
          expect(subject.move_queue.size).to eq(3) # 3 = 2 assocs + 1 bookmark
        end
      end # context
    end # describe
  end # module
end # module
