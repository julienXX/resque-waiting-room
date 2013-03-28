# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib/resque/plugins", __FILE__)
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
  s.files         += Dir.glob("lib/**/*")
  s.files         += Dir.glob("spec/**/*")

  s.add_development_dependency 'rake'
  s.add_development_dependency 'resque'
end
