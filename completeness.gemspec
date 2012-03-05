# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "completeness/version"

Gem::Specification.new do |s|
  s.name        = "completeness"
  s.version     = Completeness::VERSION
  s.authors     = ["Dima Samodurov"]
  s.email       = ["dimasamodurov@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{"Completeness" calculates percentage of populated fields of the object.}
  s.description = %q{Common use case: Determine the completeness of the user profile.}

  s.rubyforge_project = "completeness"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "redcarpet"
  s.add_development_dependency "turn"
  s.add_development_dependency "yard"

  s.add_runtime_dependency "activesupport"
end
