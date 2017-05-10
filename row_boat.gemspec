# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "row_boat/version"

Gem::Specification.new do |spec|
  spec.name          = "row_boat"
  spec.version       = RowBoat::VERSION
  spec.authors       = ["Michael Crismali"]
  spec.email         = ["michael@crismali.com"]

  spec.summary       = "Turn the rows of your CSV into rows in your database"
  spec.description   = "Turn the rows of your CSV into rows in your database"
  spec.homepage      = "https://github.com/devmynd/row_boat"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rubocop", "~> 0.48.1"
  spec.add_development_dependency "rspec", "~> 3.0"
end
