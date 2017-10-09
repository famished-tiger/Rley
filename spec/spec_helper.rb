# File: spec_helper.rb
# Purpose: utility file that is loaded by all our RSpec files

require 'simplecov'
require 'coveralls'

Coveralls.wear!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
)

require 'pp'    # Use pretty-print for debugging purposes
require 'rspec' # Use the RSpec framework


RSpec.configure do |config|
  config.expect_with :rspec do |c|
    # Disable the `should` syntax...
    c.syntax = :expect
  end

  # Display stack trace in case of failure
  config.full_backtrace = true
end

# End of file
