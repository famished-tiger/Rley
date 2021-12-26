# frozen_string_literal: true

# Re-use datatypes defined in iteration 2
require_relative '../iter_2/toml_datatype'
require 'date'
require 'forwardable'

# Class implementing the TOML unquoted key data type.
class QuotedKey < TOMLDatatype
  # Method to obtain the text representation of the object.
  # @return [String]
  def to_str
    value
  end

  protected

  def validated_value(aValue, _format)
    unless aValue.is_a?(String)
      raise StandardError, "Invalid string value #{aValue}"
    end

    aValue
  end
end # class

# Class implementing the TOML offset date-time data type.
class TOMLOffsetDateTime < TOMLDatatype
  extend Forwardable
  def_delegators :@value, :year, :mon, :mday, :hour, :min, :sec, :usec, :utc_offset

  protected

  # @param aValue [String] date in yyyy-mm-ddThh:mm:ss[.sec_frac]+mm::ss format
  def validated_value(aValue, _format)
    unless aValue.is_a?(String)
      raise StandardError, "Expected a string value #{aValue}"
    end
    (date_literal, time_literal) = aValue.split(/[Tt ]/)
    (year, month, day) = date_literal.split('-').map(&:to_i)
    unless Date.valid_date?(year, month, day)
      raise StandardError, "Invalid date value yyyy-mm-dd: #{year}-#{month}-#{day}"
    end
    offset =nil
    time_literal.sub!(/(?:[Zz]|(?:[+-]\d\d:\d\d))$/) { |match| offset = match; '' }
    (hour, min, sec) = time_literal.split(':')
    (seconds, subsec) = sec.split('.')
    base = Time.new(year, month, day, hour.to_i, min.to_i, seconds.to_i, offset)
    base + ("0.#{subsec}").to_f
  end
end # class

# Class implementing the TOML local date-time data type.
class TOMLLocalDateTime < TOMLDatatype
  extend Forwardable
  def_delegators :@value, :year, :mon, :mday, :hour, :min, :sec, :usec

  protected

  # @param aValue [String] date in yyyy-mm-ddThh:mm:ss[.sec_frac] format
  def validated_value(aValue, _format)
    unless aValue.is_a?(String)
      raise StandardError, "Expected a string value #{aValue}"
    end
    (date_literal, time_literal) = aValue.split(/[Tt ]/)
    (year, month, day) = date_literal.split('-').map(&:to_i)
    unless Date.valid_date?(year, month, day)
      raise StandardError, "Invalid date value yyyy-mm-dd: #{year}-#{month}-#{day}"
    end

    (hour, min, sec) = time_literal.split(':')
    (seconds, subsec) = sec.split('.')
    us = subsec ? ("0.#{subsec}".to_f * 1000000) : nil
    Time.local(year, month, day, hour.to_i, min.to_i, sec.to_i, us)
  end
end # class

# Class implementing the TOML local date data type.
class TOMLLocalDate < TOMLDatatype
  extend Forwardable
  def_delegators :@value, :year, :mon, :mday

  protected

  # @param aValue [String] date in yyyy-mm-dd format
  def validated_value(aValue, _format)
    unless aValue.is_a?(String)
      raise StandardError, "Expected a string value #{aValue}"
    end
    (year, month, day) = aValue.split('-').map(&:to_i)
    unless Date.valid_date?(year, month, day)
      raise StandardError, "Invalid date value yyyy-mm-dd: #{year}-#{month}-#{day}"
    end
    Date.new(year, month, day)
  end
end # class

# Class implementing the TOML local time data type.
class TOMLLocalTime < TOMLDatatype
  extend Forwardable
  def_delegators :@value, :hour, :min, :sec, :usec

  protected

  # @param aValue [String] date in hh:mm:ss[.sec_frac] format
  def validated_value(aValue, _format)
    unless aValue.is_a?(String)
      raise StandardError, "Expected a string value #{aValue}"
    end
    (hour, min, sec) = aValue.split(':')
    (seconds, subsec) = sec.split('.')
    us = subsec ? ("0.#{subsec}".to_f * 1000000) : nil
    nunc = Time.new
    Time.local(nunc.year, nunc.month, nunc.day, hour.to_i, min.to_i, sec.to_i, us)
  end
end # class
