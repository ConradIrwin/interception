Gem::Specification.new do |s|
  s.name = "interception"
  s.version = "0.5"
  s.license = "MIT"
  s.author = "Conrad Irwin"
  s.email = "conrad.irwin@gmail.com"
  s.homepage = "http://github.com/ConradIrwin/interception"
  s.summary = "Intercept exceptions as they are being raised"
  s.description = "Provides a cross-platform ability to intercept all exceptions as they are raised."

  s.files = `git ls-files`.split("\n")
  s.extensions = "ext/extconf.rb"
  s.require_path = "lib"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_runtime_dependency 'binding_of_caller', "~> 0.7"
end
