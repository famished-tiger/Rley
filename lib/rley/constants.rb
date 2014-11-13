# File: constants.rb
# Purpose: definition of Rley constants.

module Rley # Module used as a namespace
  # The version number of the gem.
  Version = '0.0.06'

  # Brief description of the gem.
  Description = "Ruby implementation of the Earley's parsing algorithm"

  # Constant Rley::RootDir contains the absolute path of Rley's
  # start directory. Note: it also ends with a slash character.
  unless defined?(RootDir)
    # The initialisation of constant RootDir is guarded in order
    # to avoid multiple initialisation (not allowed for constants)

    # The start folder of Rley.
    RootDir = begin
      require 'pathname' # Load Pathname class from standard library
      startdir = Pathname(__FILE__).dirname.parent.parent.expand_path
      startdir.to_s + '/' # Append trailing slash character to it
    end
  end
end # module

# End of file
