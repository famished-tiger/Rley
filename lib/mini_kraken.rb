# frozen_string_literal: true

# This file acts as a jumping-off point for loading dependencies expected
# for a MiniKraken client.

require_relative './mini_kraken/version'
require_relative './mini_kraken/glue/dsl'

module MiniKraken
  class Error < StandardError; end
  # Your code goes here...
end

# End of file
