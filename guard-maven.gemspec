# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guard/maven/version'

Gem::Specification.new do |spec|
  spec.name          = "guard-maven"
  spec.version       = Guard::MavenVersion::VERSION
  spec.authors       = ["Jeremy Baker"]
  spec.email         = ["jhubert@gmail.com"]
  spec.description   = %q{Guard for Maven runs the clean and test commands for a Maven project}
  spec.summary       = %q{Guard for Maven}
  spec.homepage      = "https://github.com/jhubert/guard-maven"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'guard', '~> 1.8.2'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
