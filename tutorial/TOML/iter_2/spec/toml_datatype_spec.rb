# frozen_string_literal: true

require_relative 'spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../toml_datatype'

describe TOMLBoolean do
  subject(:boolean) { described_class.new('true') }

  context 'Initialization:' do
    it "is initialized with 'true' or 'false' text" do
      expect { described_class.new('true') }.not_to raise_error
    end

    it 'has a Ruby boolean value' do
      expect(boolean.value).to equal(true)
      instance = described_class.new('false')
      expect(instance.value).to equal(false)
    end
  end # context
end # describe


describe TOMLInteger do
  subject { described_class.new('true') }

  context 'Initialization:' do
    it 'is initialized with a decimal integer literal' do
      expect { described_class.new('42') }.not_to raise_error
    end

    it 'is initialized with a hexadecimal integer literal' do
      expect { described_class.new('0xDEADBEEF', :hex) }.not_to raise_error
    end

    it 'is initialized with an octal integer literal' do
      expect { described_class.new('0o01234567', :oct) }.not_to raise_error
    end

    it 'is initialized with a binary integer literal' do
      expect { described_class.new('0b11010110', :bin) }.not_to raise_error
    end

    it 'initializes its value with a decimal integer literal' do
      cases = [
        ['+99', 99],
        ['42', 42],
        ['0', 0],
        ['-17', -17],
        ['1_000', 1_000],
        ['5_349_221', 5_349_221],
        ['53_49_221', 53_49_221],
        ['1_2_3_4_5', 12345]
      ]
      cases.each do |(literal, exp_value)|
        instance = described_class.new(literal)
        expect(instance.value).to eq(exp_value)
      end
    end

    it 'initializes its value with a hexadecimal integer literal' do
      cases = [
        ['0xDEADBEEF', 0xdeadbeef],
        ['0xdeadbeef', 0xdeadbeef],
        ['0xdead_beef', 0xdeadbeef],
        ['0x0', 0]
      ]
      cases.each do |(literal, exp_value)|
        instance = described_class.new(literal, :hex)
        expect(instance.value).to eq(exp_value)
      end
    end

    it 'initializes its value with an octal integer literal' do
      cases = [
        ['0o01234567', 0o01234567],
        ['0o0', 0],
        ['0o755', 0o755]
      ]
      cases.each do |(literal, exp_value)|
        instance = described_class.new(literal, :oct)
        expect(instance.value).to eq(exp_value)
      end
    end

    it 'initializes its value with a binary integer literal' do
      cases = [
        ['0b11010110', 0b11010110],
        ['0b0', 0]
      ]
      cases.each do |(literal, exp_value)|
        instance = described_class.new(literal, :bin)
        expect(instance.value).to eq(exp_value)
      end
    end
  end # context
end # describe
