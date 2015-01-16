# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'binero_deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "binero-deploy"
  spec.version       = BineroDeploy::VERSION
  spec.authors       = ["roback"]
  spec.email         = ["mattias.roback@gmail.com"]
  spec.summary       = "CLI for deploying PHP/HTML websites to Binero."
  spec.description   = "CLI for deploying, backing up and reverting a release of a PHP/HTML website on Binero."
  spec.homepage      = "https://github.com/roback/binero-deploy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "net-ssh", "~> 2.9"
  spec.add_runtime_dependency "net-scp", "~> 1.2"
  spec.add_runtime_dependency "colorize", "~> 0.7"
  spec.add_runtime_dependency "ruby-progressbar", "~> 1.5"
  spec.add_runtime_dependency "thor", "~> 0.19"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.4"
end
