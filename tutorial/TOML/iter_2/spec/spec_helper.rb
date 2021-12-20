# frozen_string_literal: true

require 'rspec' # Use the RSpec framework

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    # Disable the `should` syntax
    c.syntax = :expect
  end

  # Display stack trace in case of failure
  config.full_backtrace = true
end
