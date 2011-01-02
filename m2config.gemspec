Gem::Specification.new do |s|
  s.name        = "m2config"
  s.version     = "0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Lukas Fittl"]
  s.email       = ["lukas@fittl.com"]
  s.summary     = "Mongrel2 Thrift interface"
  s.description = "Thrift interface for Mongrel2 configuration database."
  
  s.required_rubygems_version = ">= 1.2"
  
  s.add_dependency "thrift"
  s.add_dependency "sqlite3-ruby"
  s.add_development_dependency "test-spec"
 
  s.files        = Dir.glob("lib/**") + Dir.glob("*.thrift")
  s.executables  = ['m2configsrv']
  s.require_path = 'lib'
end