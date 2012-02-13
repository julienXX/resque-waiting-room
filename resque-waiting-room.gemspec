# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib/resque/plugins", __FILE__)
puts $:
require "version"

Gem::Specification.new do |s|
  s.name        = "resque-waiting-room"
  s.version     = Resque::Plugins::WaitingRoom::VERSION
  s.authors     = ["Julien Blanchard"]
  s.email       = ["julien@sideburns.eu"]
  s.homepage    = "https://www.github.com/julienXX/resque-waiting-room"
  s.summary     = %q{Put your Resque jobs in a waiting room}
  s.description = %q{Throttle your Resque jobs}

  s.rubyforge_project = "resque-waiting-room"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake', '~>0.9.2.2'
  s.add_development_dependency 'resque', '~>1.19.0'
  s.add_development_dependency 'rspec', '~>2.8.0'
  s.add_development_dependency 'fuubar', '~>1.0.0'
  s.add_development_dependency 'spork', '~>0.9.0'
  s.add_development_dependency 'guard', '~>0.10.0'
  s.add_development_dependency 'guard-rspec', '~>0.6.0'
  s.add_development_dependency 'guard-spork', '~>0.3.0'
  s.add_development_dependency 'rb-fsevent', '~>0.4.3.1'
end
