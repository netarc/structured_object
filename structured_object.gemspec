require File.expand_path("../lib/structured_object/version", __FILE__)

Gem::Specification.new do |s|
  s.name          = "structured_object"
  s.version       = StructuredObject::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Joshua Hollenbeck"]
  s.email         = ["josh.hollenbeck@citrusbyte.com"]
  s.homepage      = "http://github.com/netarc/structured_object"
  s.summary       = "Ruby Structured Object"
  s.description   = "StructuredObject is a tool for grouping data for easy serialization or unserialization."

  s.required_rubygems_version = ">= 1.3.6"


  s.add_development_dependency "rake"
  s.add_development_dependency "contest", ">= 0.1.2"
  s.add_development_dependency "mocha"
  s.add_development_dependency "ruby-debug"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path  = 'lib'
end

