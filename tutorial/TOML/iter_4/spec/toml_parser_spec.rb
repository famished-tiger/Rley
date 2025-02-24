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
        expect(root).to be_a(TOMLTableNode)
        expect(root.subnodes).to be_empty
      end
    end
  end # context

  context 'Parsing simple keyval:' do
    it 'parses key - integer literal' do
      source = 'key = -42'
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(TOMLTableNode)
      expect(root.subnodes.size).to eq(1)
      keyval = root.subnodes[0]
      expect(keyval.key.value).to eq('key')
      expect(keyval.val.value).to eq(-42)
    end

    it 'parses key - date literal' do
      source = 'key = 1915-11-25'
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(TOMLTableNode)
      expect(root.subnodes.size).to eq(1)
      keyval = root.subnodes[0]
      expect(keyval.key.value).to eq('key')
      expect(keyval.val.value.value.to_s).to eq('1915-11-25')
    end
  end

  context 'Parsing tables:' do
    it 'parses a table section' do
      source = <<-TOML
      [database]
      enabled = true
      ip = "10.0.0.1"
      TOML
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(TOMLTableNode)
      expect(root.subnodes.size).to eq(1)
      db_table = root['database']
      expect(db_table).to be_a(TOMLTableNode)
      expect(db_table.subnodes.size).to eq(2)
      expect(db_table['enabled'].value).to be_truthy
      expect(db_table['ip'].value).to eq('10.0.0.1')
    end

    it 'parses multiple table sections' do
      source = <<-TOML
        [owner]
        name = "Tom Sawyer"
        dob = 1909-05-27T07:32:00-08:00

        [database]
        enabled = true
      TOML
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(TOMLTableNode)
      expect(root.subnodes.size).to eq(2)

      owner_table = root['owner']
      expect(owner_table).to be_a(TOMLTableNode)
      expect(owner_table.subnodes.size).to eq(2)
      expect(owner_table['name'].value).to eq('Tom Sawyer')
      expect(owner_table['dob'].value).to be_a(TOMLOffsetDateTime)

      db_table = root['database']
      expect(db_table).to be_a(TOMLTableNode)
      expect(db_table.subnodes.size).to eq(1)
      expect(db_table['enabled'].value).to be_truthy
    end

    it 'parses dotted keys' do
      source = <<-TOML
        name = "Orange"
        physical.color = "orange"
        physical.shape = "round"
        site."google.com" = true
      TOML
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(TOMLTableNode)
      expect(root.subnodes.size).to eq(3)
      expect(root['name'].value).to eq('Orange')

      expect(root['physical']).to be_a(TOMLTableNode)
      physical = root['physical']
      expect(physical['color'].value).to eq('orange')
      expect(physical['shape'].value).to eq('round')

      expect(root['site']).to be_a(TOMLTableNode)
      expect(root['site']['google.com'].value).to eq(true)
    end

    it 'parses dotted key table' do
      source = <<-TOML
      [database]
      enabled = true

      [server.alpha]
      ip = "10.0.0.1"
      role = "frontend"
      TOML
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(TOMLTableNode)
      expect(root.subnodes.size).to eq(2)
      db_table = root['database']
      expect(db_table).to be_a(TOMLTableNode)
      expect(db_table.subnodes.size).to eq(1)
      expect(db_table['enabled'].value).to be_truthy

      srvr_table = root['server']
      expect(srvr_table.subnodes.size).to eq(1)

      alpha_table = srvr_table['alpha']
      expect(alpha_table.subnodes.size).to eq(2)
      expect(alpha_table['ip'].value).to eq('10.0.0.1')
      expect(alpha_table['role'].value).to eq('frontend')
    end

    it 'parses arrays' do
      source = <<-TOML
        ports = [25, 443]
      TOML
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(TOMLTableNode)
      expect(root.subnodes.size).to eq(1)
      port_array = root['ports']
      expect(port_array).to be_a(TOMLArrayNode)
      expect(port_array.subnodes[0].value).to eq(25)
      expect(port_array.subnodes[1].value).to eq(443)
    end

    it 'parses inline tables' do
      source = <<-TOML
        center = { x = 5, y = -17 }
      TOML
      ptree = parser.parse(source)
      root = ptree.root
      expect(root).to be_a(TOMLTableNode)
      expect(root.subnodes.size).to eq(1)
      center_table = root['center']
      expect(center_table.subnodes[0].key.value).to eq('x')
      expect(center_table.subnodes[0].val.value).to eq(5)
      expect(center_table.subnodes[1].key.value).to eq('y')
      expect(center_table.subnodes[1].val.value).to eq(-17)
    end
  end
end # describe
