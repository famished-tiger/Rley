require 'rubygems'

# Testing-specific tasks


# RSpec as testing tool
require 'rspec/core/rake_task'
desc 'Run RSpec'
RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end


# Combine RSpec tests
desc 'Run tests, with RSpec'
task test: [:spec]


# Default rake task
task default: :test

# End of file
