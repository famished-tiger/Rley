# frozen_string_literal: true

# File: env.rb
# Purpose: Allow Cucumber to load the sample application configuration
# and hooks.
# It also demonstrates what to do in your env.rb file
# to use the Macros4Cuke gem.

require 'rspec/expectations'
require_relative 'rule_parser'
require_relative 'parse_forest_builder'


module Rley4Cuke # Use the module as a namespace
  # Class created just for testing and demonstration purposes.
  # Its instance, will record the output emitted by the steps.
  class RleyWorld
    include RuleParser # Mixin module
    include ForestBuilder # Mixin module
  end # class
end # module


=begin rdoc
Cucumber workflow.
-Selecting the profile (from the command-line or using the default one)
-Load & execute all the Ruby files in the features/support folder.
-Execute the AfterConfiguration hook.
-For every .feature file in features folder:
-- Load the file,
-- Parse it (= try to create a parse tree of it)
--- Pre-process per scenario (i.e. add background steps)
-Load all *.rb from features/step_definitions
-- For every scenario instance.
--- Create a World instance.
--- Execute the Before proc.
---- Per matching step, execute the step definition's block
-----Execute the AfterStep proc.
--- Execute the After proc.
=end

########################################
# Global hooks
########################################

########################################
# BeforeAll
# Place below the code that will be executed before the visit phase

########################################
# AfterAll. Uses the standard Kernel::at_exit method
#
at_exit do
  # Do something
end

# For testing purpose we override the default Cucumber behaviour
# making our world object an instance of the TracingWorld class
World { Rley4Cuke::RleyWorld.new }


########################################
# Scenario hooks
########################################

########################################
# Before hook
# The Before block code will be executed before each scenario instance.
# For a genuine scenario, the scenario object (a Cucumber::Ast::Scenario) is passed as the block argument
# For a scenario outline (with a table), a Cucumber::Ast::OutlineTable::ExampleRow is passed as block argument.
# New with Cucumber 0.3 and above:
# It is possible to pass to the Before method one or more tag names. Only the scenarios having the tags will be considered.
# Example syntax: Before('@tag1', ' @tag2') do ...
Before do |scenario|
  # Do something
end


########################################
# After hook
# The After block code is executed after each scenario instance.
# For a genuine scenario, the scenario object (a Cucumber::Ast::Scenario) is passed as the block argument
# For a scenario outline (with a table), a Cucumber::Ast::OutlineTable::ExampleRow is passed as block argument.
# From Cucumber wiki: the 'scenario' argument can be inspected with the following methods:
# #failed?, #passed? or #exception methods.
After do |scenario|
  # Do something
end

# End of file
