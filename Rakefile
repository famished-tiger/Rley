require 'bundler/gem_tasks'
require 'rspec/core/rake_task' # Rspec as testing tool
require 'cucumber/rake/task' # Cucumber as testing tool

desc 'Run RSpec'
RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

Cucumber::Rake::Task.new do |_|
end

# Combine RSpec and Cucumber tests
desc 'Run tests, with RSpec and Cucumber'
task test: %i[spec cucumber]

# Default rake task
task default: :test
