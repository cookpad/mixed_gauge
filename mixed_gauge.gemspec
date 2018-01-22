# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mixed_gauge/version'

Gem::Specification.new do |spec|
  spec.name          = 'mixed_gauge'
  spec.version       = MixedGauge::VERSION
  spec.authors       = ['Taiki Ono']
  spec.email         = ['taiks.4559@gmail.com']

  spec.summary       = %{A simple and robust ActiveRecord extension for database sharding.}
  spec.description   = %{#{spec.summary} Supports shards management with hash slots, re-sharding support, efficient KVS queries, limited RDB queries.}
  spec.homepage      = 'https://github.com/taiki45/mixed_gauge'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 4.1.0'
  spec.add_dependency 'expeditor', '>= 0.1.0'
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3'
end
