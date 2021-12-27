# frozen_string_literal: true

require_relative 'spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../toml_datatype'

describe TOMLBoolean do
  subject { TOMLBoolean.new('true') }

  context 'Initialization:' do
    it "should be initialized with 'true' or 'false' text" do
      expect { TOMLBoolean.new('true') }.not_to raise_error
    end

    it 'should have a Ruby boolean value' do
      expect(subject.value).to be_equal(true)
      instance = TOMLBoolean.new('false')
      expect(instance.value).to be_equal(false)
    end
  end # context
end # describe


describe TOMLInteger do
  subject { TOMLBoolean.new('true') }

  context 'Initialization:' do
    it 'could be initialized with a decimal integer literal' do
      expect { TOMLInteger.new('42') }.not_to raise_error
    end

    it 'could be initialized with a hexadecimal integer literal' do
      expect { TOMLInteger.new('0xDEADBEEF', :hex) }.not_to raise_error
    end

    it 'could be initialized with an octal integer literal' do
      expect { TOMLInteger.new('0o01234567', :oct) }.not_to raise_error
    end

    it 'could be initialized with a binary integer literal' do
      expect { TOMLInteger.new('0b11010110', :bin) }.not_to raise_error
    end

    it 'should initialize its value with a decimal integer literal' do
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
        instance = TOMLInteger.new(literal)
        expect(instance.value).to eq(exp_value)
      end
    end

    it 'should initialize its value with a hexadecimal integer literal' do
      cases = [
        ['0xDEADBEEF', 0xdeadbeef],
        ['0xdeadbeef', 0xdeadbeef],
        ['0xdead_beef', 0xdeadbeef],
        ['0x0', 0]
      ]
      cases.each do |(literal, exp_value)|
        instance = TOMLInteger.new(literal, :hex)
        expect(instance.value).to eq(exp_value)
      end
    end

    it 'should initialize its value with an octal integer literal' do
      cases = [
        ['0o01234567', 0o01234567],
        ['0o0', 0],
        ['0o755', 0o755]
      ]
      cases.each do |(literal, exp_value)|
        instance = TOMLInteger.new(literal, :oct)
        expect(instance.value).to eq(exp_value)
      end
    end

    it 'should initialize its value with a binary integer literal' do
      cases = [
        ['0b11010110', 0b11010110],
        ['0b0', 0]
      ]
      cases.each do |(literal, exp_value)|
        instance = TOMLInteger.new(literal, :bin)
        expect(instance.value).to eq(exp_value)
      end
    end
  end # context
end # describe
