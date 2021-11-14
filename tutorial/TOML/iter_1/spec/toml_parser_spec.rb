# frozen_string_literal: true

require_relative 'spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../toml_parser'

describe TOMLParser do
  subject { TOMLParser.new }

  context 'Initialization:' do
    it 'should be initialized without argument' do
      expect { TOMLParser.new }.not_to raise_error
    end

    it 'should have its parse engine initialized' do
      expect(subject.engine).to be_kind_of(Rley::Engine)
    end
  end # context

  context 'Parsing blank files:' do
    it 'should cope with a blank input' do
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
        ptree = subject.parse(input_string)
        root = ptree.root
        expect(root).to be_kind_of(Rley::PTree::NonTerminalNode)
        expect(root.symbol.name).to eq('toml')
        expect(root.subnodes.size).to eq(1)
        expect(root.subnodes[0]).to be_kind_of(Rley::PTree::NonTerminalNode)
        expect(root.subnodes[0].symbol.name).to eq('expr-list')
        expect(root.subnodes[0].subnodes).to be_empty
      end
    end
  end # context
end # describe
