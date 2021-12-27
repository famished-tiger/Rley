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

    it 'could be initialized with a octal integer literal' do
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


describe TOMLOffsetDateTime do
  subject { TOMLLocalDateTime.new('1979-05-27T07:32:00Z') }

  context 'Initialization:' do
    # it 'should be initialized with a string' do
    #   # Case: valid date; capital letters T and Z as separator
    #   expect { TOMLOffsetDateTime.new('1979-05-27T07:32:00Z') }.not_to raise_error
    #
    #   # Case: valid date; capital letters T and small letter z as separator
    #   expect { TOMLOffsetDateTime.new('1979-05-27T07:32:00z') }.not_to raise_error
    #
    #   # Case: valid date; small letters t and z as separator
    #   expect { TOMLOffsetDateTime.new('1979-05-27t07:32:00z') }.not_to raise_error
    #
    #   # Case: valid date; capital letters T and Z as separator
    #   expect { TOMLOffsetDateTime.new('1979-05-27T07:32:00-07:00') }.not_to raise_error
    # end
    #
    # it 'should complain when given invalid date' do
    #   # Case: invalid date
    #   err = Date::Error
    #   msg = 'invalid date'
    #   expect { TOMLOffsetDateTime.new('1979-02-29T00:32:00Z') }.to raise_error(err, msg)
    # end

    it 'should know its date value' do
      dt = TOMLOffsetDateTime.new('1979-05-27T05:32:07.999999-07:00')
      expect(dt.value).to be_kind_of(Time)
      expect(dt.year).to eq(1979)
      expect(dt.mon).to eq(5)
      expect(dt.mday).to eq(27)
      expect(dt.hour).to eq(5)
      expect(dt.min).to eq(32)
      expect(dt.sec).to eq(7)
      expect(dt.utc_offset).to eq(-7 * 3600)
    end
  end # context
end # describe


describe TOMLLocalDateTime do
  subject { TOMLLocalDateTime.new('1979-05-27T05:32:07.999999') }

  context 'Initialization:' do
    it 'should be initialized with a string' do
      # Case: valid date; capital letter T as separator
      expect { TOMLLocalDateTime.new('1979-05-27T00:32:00.999999') }.not_to raise_error

      # Case: valid date; small letter t as separator
      expect { TOMLLocalDateTime.new('1979-05-27t00:32:00.999999') }.not_to raise_error

      # Case: valid date; space as separator
      expect { TOMLLocalDateTime.new('1979-05-27 00:32:00.999999') }.not_to raise_error
    end

    it 'should complain when given invalid date' do
      # Case: invalid date
      err = StandardError
      msg = 'Invalid date value yyyy-mm-dd: 1979-2-29'
      expect { TOMLLocalDate.new('1979-02-29T00:32:00.999999') }.to raise_error(err, msg)
    end

    it 'should know its date value' do
      cases = [
        TOMLLocalDateTime.new('1979-05-27T05:32:07.999999'),
        TOMLLocalDateTime.new('1979-05-27t05:32:07.999999'),
        TOMLLocalDateTime.new('1979-05-27 05:32:07.999999')
      ]
      cases.each do |dt|
        expect(dt.value).to be_kind_of(Time)
        expect(dt.year).to eq(1979)
        expect(dt.mon).to eq(5)
        expect(dt.mday).to eq(27)
        expect(dt.hour).to eq(5)
        expect(dt.min).to eq(32)
        expect(dt.sec).to eq(7)
        expect(dt.usec).to eq(999999)
      end
    end
  end # context
end # describe

describe TOMLLocalDate do
  subject { TOMLLocalDate.new('1979-05-27') }

  context 'Initialization:' do
    it 'should be initialized with a string' do
      # Case: valid date
      expect { TOMLLocalDate.new('1979-05-27') }.not_to raise_error
    end

    it 'should complain when given invalid date' do
      # Case: invalid date
      err = StandardError
      msg = 'Invalid date value yyyy-mm-dd: 1979-2-29'
      expect { TOMLLocalDate.new('1979-02-29') }.to raise_error(err, msg)
    end

    it 'should know its date value' do
      expect(subject.value).to be_kind_of(Date)
      expect(subject.year).to eq(1979)
      expect(subject.mon).to eq(5)
      expect(subject.mday).to eq(27)
    end
  end # context
end # describe

describe TOMLLocalTime do
  subject { TOMLLocalTime.new('07:32:00') }

  context 'Initialization:' do
    it 'should be initialized with a string' do
      # Case: round second
      expect { TOMLLocalTime.new('07:32:00') }.not_to raise_error

      # Case: fractional part
      expect { TOMLLocalTime.new('07:32:00.999999') }.not_to raise_error
    end

    it 'should know its time value' do
      expect(subject.value).to be_kind_of(Time)
      expect(subject.hour).to eq(7)
      expect(subject.min).to eq(32)
      expect(subject.sec).to be_zero

      instance = TOMLLocalTime.new('07:32:00.999999')
      expect(instance.value).to be_kind_of(Time)
      expect(instance.hour).to eq(7)
      expect(instance.min).to eq(32)
      expect(instance.sec).to be_zero
      expect(instance.usec).to eq(999999)
    end
  end # context
end # describe
