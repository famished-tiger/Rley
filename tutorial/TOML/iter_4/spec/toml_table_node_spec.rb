# frozen_string_literal: true

require_relative 'spec_helper' # Use the RSpec framework

require_relative '../../iter_3/toml_datatype'
require_relative '../toml_keyval_node'

# Load the class under test
require_relative '../toml_table_node'

describe TOMLTableNode do
  subject(:table_node) { described_class.new([]) }

  context 'Initialization:' do
    it 'is initialized with an array' do
      expect { described_class.new([]) }.not_to raise_error
    end

    it 'is empty' do
      expect(table_node.subnodes).to be_empty
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

    it 'accepts the addition of keyval' do
      table_node.add_keyval(keyval_aa)
      expect(table_node.subnodes.size).to eq(1)
      expect(table_node.subnodes[0].key).to eq('a')
      expect(table_node.subnodes[0].val).to eq('a')

      table_node.add_keyval(keyval_bb)
      expect(table_node.subnodes.size).to eq(2)
      expect(table_node.subnodes[1].key).to eq('b')
      expect(table_node.subnodes[1].val).to eq('b')
    end

    it 'retrieves a keyval with given key value' do
      expect(table_node[keyval_aa.key]).to be_nil

      table_node.add_keyval(keyval_aa)
      expect(table_node[keyval_aa.key]).to eq(keyval_aa.val)
      expect(table_node['a']).to eq(keyval_aa.val)

      table_node.add_keyval(keyval_bb)
      expect(table_node[keyval_aa.key]).to eq(keyval_aa.val)
      expect(table_node[keyval_bb.key]).to eq(keyval_bb.val)
      expect(table_node['b']).to eq(keyval_bb.val)

      expect(table_node[keyval_ac.key]).to eq(keyval_aa.val)
    end
  end # context
end # describe
