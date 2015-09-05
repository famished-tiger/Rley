# encoding: utf-8
# File: rley.gemspec
# Gem specification file for the Rley project.

require 'rubygems'

# The next line generates an error with Bundler
require_relative './lib/rley/constants'


RLEY_GEMSPEC = Gem::Specification.new do |pkg|
  pkg.name = 'rley'
  pkg.version = Rley::Version
  pkg.author = 'Dimitri Geshef'
  pkg.email = 'famished.tiger@yahoo.com'
  pkg.homepage = 'https://github.com/famished-tiger/Rley'
  pkg.platform = Gem::Platform::RUBY
  pkg.summary = Rley::Description
  pkg.description = 'A general parser using the Earley algorithm.'
  pkg.post_install_message = <<EOSTRING
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Thank you for installing Rley...
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EOSTRING
  pkg.rdoc_options << '--charset=UTF-8 --exclude="examples|features|spec"'
  file_list = Dir[
    '.rubocop.yml', 
    '.rspec', 
    '.ruby-gemset', 
    '.ruby-version', 
    '.simplecov',
    '.travis.yml',  
    '.yardopts', 
    'Gemfile', 
    'Rakefile',
    'CHANGELOG.md',
    'LICENSE.txt', 
    'README.md',
    'examples/**/*.rb',
    'lib/*.*', 
    'lib/**/*.rb',
    'spec/**/*.rb'
  ]
  pkg.files = file_list
  pkg.test_files = Dir[ 'spec/**/*_spec.rb' ]

  pkg.require_path = 'lib'

  pkg.extra_rdoc_files = ['README.md']

  pkg.add_development_dependency('rake', ['>= 10.0.0'])
  pkg.add_development_dependency('rspec', ['>= 3.0.0'])
  pkg.add_development_dependency('simplecov', ['>= 0.8.0'])
  pkg.add_development_dependency('coveralls', ['>= 0.7.0'])
  pkg.add_development_dependency('rubygems', ['>= 2.0.0'])

  pkg.license = 'MIT'
  pkg.required_ruby_version = '>= 1.9.3'
end

if $PROGRAM_NAME == __FILE__
  require 'rubygems/package'
  Gem::Package.build(RLEY_GEMSPEC)
end

# End of file
