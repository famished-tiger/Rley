# frozen_string_literal: true

# File: rley.gemspec
# Gem specification file for the Rley project.

require 'rubygems'

# The next line generates an error with Bundler
require_relative './lib/rley/constants'

def pkg_description(aPackage)
  aPackage.name = 'rley'
  aPackage.version = Rley::Version
  aPackage.author = 'Dimitri Geshef'
  aPackage.email = 'famished.tiger@yahoo.com'
  aPackage.homepage = 'https://github.com/famished-tiger/Rley'
  aPackage.platform = Gem::Platform::RUBY
  aPackage.summary = Rley::Description
  aPackage.description = 'A general parser using the Earley algorithm.'
  aPackage.post_install_message = <<EOSTRING
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Thank you for installing Rley...
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EOSTRING
end

def pkg_files(aPackage)
  file_list = Dir[
    '.rubocop.yml',
    '.rspec',
    '.ruby-gemset',
    '.ruby-version',
    '.yardopts',
    'appveyor.yml',
    'Gemfile',
    'Rakefile',
    'CHANGELOG.md',
    'LICENSE.txt',
    'README.md',
    'examples/**/*.*',
    'lib/*.*',
    'lib/**/*.rb',
    'spec/**/*.rb'
  ]
  aPackage.files = file_list
  aPackage.test_files = Dir['spec/**/*_spec.rb']
  aPackage.require_path = 'lib'
end

def pkg_documentation(aPackage)
  aPackage.rdoc_options << '--charset=UTF-8 --exclude="examples|features|spec"'
  aPackage.extra_rdoc_files = ['README.md']
end


RLEY_GEMSPEC = Gem::Specification.new do |pkg|
  pkg_description(pkg)
  pkg_files(pkg)
  pkg_documentation(pkg)

  # Here we have the runtime external dependency (prime library has been demoted to a bundled gem)
  pkg.add_runtime_dependency('prime', '~> 0.1.2')

  # Here we have the development external dependencies
  pkg.add_development_dependency 'rake', '~> 13'
  pkg.add_development_dependency 'rspec', '~> 3.12'
  pkg.add_development_dependency 'yard', '~> 0.9.34'
  pkg.license = 'MIT'
  pkg.required_ruby_version = '>= 3.2.0'
end

# End of file
