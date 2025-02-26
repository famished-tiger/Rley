# frozen_string_literal: true

require_relative 'spec_helper' # Use the RSpec framework

require_relative '../toml_ast_visitor'
require_relative '../toml_parser'

# Load the class under test
require_relative '../toml_2_ruby'

describe TOML2Ruby do
  def visitor_for(source)
    parser = TOMLParser.new
    ast_tree = parser.parse(source)
    TOMLASTVisitor.new(ast_tree)
  end

  subject(:translator) { described_class.new }

  context 'Initialization:' do
    it 'is initialized with an array' do
      expect { described_class.new }.not_to raise_error
    end
  end # context

  context 'Conversion to Ruby:' do
    it 'converts an empty input to an empty Hash' do
      expect(translator.convert(visitor_for(''))).to be_empty
    end

    it 'converts a single keyval to one Hash pair' do
      source = <<-TOML
        title = "TOML Example"
      TOML
      converted = translator.convert(visitor_for(source))
      expect(converted).to be_a(Hash)
      expect(converted.to_s).to eq('{"title" => "TOML Example"}')
    end

    it 'converts a table to a nested Hash' do
      source = <<-TOML
        title = "TOML Example"

        [owner]
        name = "Tom Preston-Werner"
        dob = 1979-05-27T07:32:00-08:00
      TOML
      converted = translator.convert(visitor_for(source))
      expect(converted).to be_a(Hash)
      expect(converted.size).to eq(2)
      expect(converted['title']).to eq('TOML Example')
      nested = converted['owner']
      expect(nested).to be_a(Hash)
      expect(nested.size).to eq(2)
      nested_str = '{"name" => "Tom Preston-Werner", "dob" => 1979-05-27 07:32:00 -0800}'
      expect(nested.to_s).to eq(nested_str)
    end

    it 'converts tables, arrays, inline tables' do
      source = <<-TOML
        title = "TOML Example"

        [owner]
        name = "Tom Preston-Werner"
        dob = 1979-05-27T07:32:00-08:00

        [database]
        enabled = true
        ports = [ 8000, 8001, 8002 ]
        data = [ ["delta", "phi"], [3.14] ]
        temp_targets = { cpu = 79.5, case = 72.0 }
      TOML
      converted = translator.convert(visitor_for(source))
      expect(converted).to be_a(Hash)
      expect(converted.size).to eq(3)
      expect(converted['title']).to eq('TOML Example')
      owner = converted['owner']
      expect(owner).to be_a(Hash)
      expect(owner.size).to eq(2) # Contents was tested in previous test

      db_table = converted['database']
      expect(db_table).to be_a(Hash)
      expect(db_table.size).to eq(4)
      expect(db_table['enabled']).to be_truthy
      expect(db_table['ports']).to eq([8000, 8001, 8002])
      expect(db_table['data']).to eq([%w[delta phi], [3.14]])
      expect(db_table['temp_targets'].to_s).to eq('{"cpu" => 79.5, "case" => 72.0}')
    end

    it 'converts dotted keys,' do
      source = <<-TOML
        title = "TOML Example"

        [owner]
        name = "Tom Preston-Werner"
        dob = 1979-05-27T07:32:00-08:00

        [database]
        enabled = true
        ports = [ 8000, 8001, 8002 ]
        data = [ ["delta", "phi"], [3.14] ]
        temp_targets = { cpu = 79.5, case = 72.0 }

        [servers]

        [servers.alpha]
        ip = "10.0.0.1"
        role = "frontend"
        physical.color = "orange"
        physical.shape = "round"
        site."google.com" = true

        [servers.beta]
        ip = "10.0.0.2"
        role = "backend"
      TOML
      converted = translator.convert(visitor_for(source))
      expect(converted.size).to eq(4)
      expect(converted['title']).to eq('TOML Example')
      expect(converted['owner'].size).to eq(2) # Contents was already tested

      expect(converted['database'].size).to eq(4) # Contents was already tested

      srvr_table = converted['servers']
      expect(srvr_table.size).to eq(2)
      alpha_table = srvr_table['alpha']
      expect(alpha_table).to be_a(Hash)
      expect(alpha_table.size).to eq(4)
      expect(alpha_table['ip']).to eq('10.0.0.1')
      expect(alpha_table['role']).to eq('frontend')
      phys_table = alpha_table['physical']
      expect(phys_table.to_s).to eq('{"color" => "orange", "shape" => "round"}')
      site_table = alpha_table['site']
      expect(site_table.to_s).to eq('{"google.com" => true}')

      beta_table = srvr_table['beta']
      expect(beta_table).to be_a(Hash)
      expect(beta_table.to_s).to eq('{"ip" => "10.0.0.2", "role" => "backend"}')
    end
  end # context
end # describe
