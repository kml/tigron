# encoding: utf-8

$:.push File.expand_path('../lib', __FILE__)
require 'tigron/version'

Gem::Specification.new do |spec|
  spec.name          = 'tigron'
  spec.version       = Tigron::VERSION
  spec.authors       = ['Kamil Lemański']
  spec.email         = ['kamil.lemanski@gmail.com']
  spec.description   = %q{Tigron Application Platform}
  spec.summary       = %q{Tigron Application Platform}
  spec.homepage      = 'https://github.com/kml/tigron'
  spec.license       = 'MIT'

  spec.files = Dir['{bin,config,lib,vendor}/**/*']
  spec.executables   = Dir["#{File.dirname(__FILE__)}/bin/*"].map{ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib', 'vendor']

  spec.add_dependency 'puma', '~> 2.5'
  spec.add_dependency 'jruby-hornetq'
  spec.add_dependency 'quartz-jruby'
  spec.add_dependency 'jmx'
  spec.add_dependency 'gene_pool'
  spec.add_dependency 'activesupport', '~> 3.2.1'

  spec.add_dependency 'backports', '3.3.0'

  spec.add_dependency 'torquebox-core', '~> 2.3.2'
  spec.add_dependency 'torquebox-messaging', '~> 2.3.2'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end

