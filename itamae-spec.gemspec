# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'itamae-spec/version'

Gem::Specification.new do |spec|
  spec.name          = "itamae-spec"
  spec.version       = ItamaeSpec::VERSION
  spec.authors       = ["kammy1231"]
  spec.email         = ["akihiro.vamps@gmail.com"]
  spec.summary       = %q{Customized version of Itamae.
Integration with Serverspec.
It can be provisioning using itamae's some AWS resources.}
  spec.homepage      = "https://github.com/kammy1231/itamae-spec"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.0")

  spec.add_runtime_dependency "aws-sdk", "~> 2"
  spec.add_runtime_dependency "serverspec", "~> 2.1"
  spec.add_runtime_dependency "itamae", "1.9.11"
  spec.add_runtime_dependency "rake"
  spec.add_runtime_dependency "multi_json"
  spec.add_runtime_dependency "io-console"
  spec.add_runtime_dependency "bundler"
  spec.add_runtime_dependency "highline"

  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "docker-api", "~> 1.20"
  spec.add_development_dependency "fakefs"
  spec.add_development_dependency "fluent-logger"
end
