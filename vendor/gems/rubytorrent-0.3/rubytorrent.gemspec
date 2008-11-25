Gem::Specification.new do |s|
  s.name = %q{rubytorrent}
  s.version = "0.3"
  
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["William Morgan and others"]
  s.date = %q{2008-11-24}
  s.description = %q{RubyTorrent is a pure-Ruby BitTorrent peer library and toolset.}
  s.email = ["william@masanjin.net"]
  s.has_rdoc = false
  s.homepage = %q{http://rubytorrent.rubyforge.org}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rubytorrent}
  s.summary = %q{rubytorrent 0.3}
  
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.2"])
    end
  end
end
