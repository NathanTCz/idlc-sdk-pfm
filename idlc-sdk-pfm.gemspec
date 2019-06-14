# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "idlc-sdk-pfm/version"

Gem::Specification.new do |spec|
  spec.name          = "idlc-sdk-pfm"
  spec.version       = Pfm::VERSION
  spec.authors       = ["Nathan Cazell"]
  spec.email         = ["nathan.cazell@imageapi.com"]

  spec.summary       = 'IDLC SDK for AWS resources - PFM'
  spec.description   = 'Provides the pfm executable for idlc-sdk. This gem is part of the IDLC SDK'
  spec.homepage      = 'https://github.com/nathantcz/idlc-sdk'
  spec.license       = 'MIT'
  spec.executables << 'pfm'

  spec.metadata = {
    'source_code_uri' => 'https://github.com/nathantcz/idlc-sdk-deploy'
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|bin)/})
  end

  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '0.48.1'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'yard'

  spec.add_runtime_dependency 'idlc-sdk-core'
  spec.add_runtime_dependency 'idlc-sdk-build'
  spec.add_runtime_dependency 'idlc-sdk-deploy'
  spec.add_runtime_dependency 'aws-sdk-s3'
  spec.add_runtime_dependency 'berkshelf'
  spec.add_runtime_dependency 'chefspec'
  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'foodcritic-junit'
  spec.add_runtime_dependency 'foodcritic', '10.3.1'
  spec.add_runtime_dependency 'ohai', '< 13'
  spec.add_runtime_dependency 'mixlib-cli'
  spec.add_runtime_dependency 'mixlib-shellout'
  spec.add_runtime_dependency 'rubocop-junit-formatter'
  spec.add_runtime_dependency 'rubocop', '0.48.1'
end
