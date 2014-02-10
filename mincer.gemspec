# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mincer/version'

Gem::Specification.new do |spec|
  spec.name          = 'mincer'
  spec.version       = Mincer.version
  spec.authors       = ['Alex Krasinsky']
  spec.email         = ['lyoshakr@gmail.com']
  spec.description   = %q{Add pagination, cache_digest, order, json generation with postgres, simple search support to all your queries}
  spec.summary       = %q{ActiveRecord::Relation wrapper for pagination, order, json, search, cache_digest support}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 4.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'kaminari'
  spec.add_development_dependency 'will_paginate'
  spec.add_development_dependency 'textacular'
end
