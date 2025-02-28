# frozen_string_literal: true

require_relative 'spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../toml_parser'

describe TOMLParser do
  subject(:parser) { described_class.new }

  context 'Initialization:' do
    it 'is initialized without argument' do
      expect { described_class.new }.not_to raise_error
    end

    it 'has its parse engine initialized' do
      expect(parser.engine).to be_a(Rley::Engine)
    end
  end # context

  context 'Parsing blank files:' do
    it 'copes with a blank input' do
      blank_inputs = [
        '', # Empty input
        (' ' * 80) + ("\n" * 20), # spaces and newlines
        begin
          input = +''
          %w[First Second Third].each do |ordinal|
            input << "# #{ordinal} comment line\r\n"
          end
          input
        end # comments only
      ]
      blank_inputs.each do |input_string|
        ptree = parser.parse(input_string)
        root = ptree.root
        expect(root).to be_a(Rley::PTree::NonTerminalNode)
        expect(root.symbol.name).to eq('toml')
        expect(root.subnodes.size).to eq(1)
        expect(root.subnodes[0]).to be_a(Rley::PTree::NonTerminalNode)
        expect(root.subnodes[0].symbol.name).to eq('expr-list')
        expect(root.subnodes[0].subnodes).to be_empty
      end
    end
  end # context

  context 'Parsing TOML expressions' do
    it 'supports array parsing' do
      source = 'ports = [ 8000, 8001, 8002 ]'
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(Rley::PTree::NonTerminalNode)
      expect(root.symbol.name).to eq('toml')
    end
  end # context
end # describe
