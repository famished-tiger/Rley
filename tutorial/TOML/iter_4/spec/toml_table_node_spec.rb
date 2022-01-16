# frozen_string_literal: true

require_relative 'spec_helper' # Use the RSpec framework

require_relative '../../iter_3/toml_datatype'
require_relative '../toml_keyval_node'

# Load the class under test
require_relative '../toml_table_node'

describe TOMLTableNode do
  subject { TOMLTableNode.new([]) }

  context 'Initialization:' do
    it 'should be initialized with an array' do
      expect { TOMLTableNode.new([]) }.not_to raise_error
    end

    it 'should be empty' do
      expect(subject.subnodes).to be_empty
    end
  end # context

  context 'Provided services:' do
    def mirror_pair(aString)
      [UnquotedKey.new(aString), TOMLString.new(aString)]
    end

    let(:keyval_aa) { TOMLKeyvalNode.new(mirror_pair('a')) }
    let(:keyval_bb) { TOMLKeyvalNode.new(mirror_pair('b')) }
    let(:keyval_ac) do
      TOMLKeyvalNode.new([UnquotedKey.new('a'), TOMLString.new('c')])
    end

    it 'should accept the addition of keyval' do
      subject.add_keyval(keyval_aa)
      expect(subject.subnodes.size).to eq(1)
      expect(subject.subnodes[0].key).to eq('a')
      expect(subject.subnodes[0].val).to eq('a')

      subject.add_keyval(keyval_bb)
      expect(subject.subnodes.size).to eq(2)
      expect(subject.subnodes[1].key).to eq('b')
      expect(subject.subnodes[1].val).to eq('b')
    end

    it 'should retrieve a keyval with given key value' do
      expect(subject[keyval_aa.key]).to be_nil

      subject.add_keyval(keyval_aa)
      expect(subject[keyval_aa.key]).to eq(keyval_aa.val)
      expect(subject['a']).to eq(keyval_aa.val)

      subject.add_keyval(keyval_bb)
      expect(subject[keyval_aa.key]).to eq(keyval_aa.val)
      expect(subject[keyval_bb.key]).to eq(keyval_bb.val)
      expect(subject['b']).to eq(keyval_bb.val)

      expect(subject[keyval_ac.key]).to eq(keyval_aa.val)
    end
  end # context
end # describe
