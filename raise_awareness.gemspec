Gem::Specification.new do |s|
  s.name = "raise_awareness"
  s.version = "0.1"
  s.author = "Conrad Irwin"
  s.email = "conrad.irwin@gmail.com"
  s.homepage = "http://github.com/ConradIrwin/raise_awareness"
  s.summary = "Easily intercept all exceptions when they happen."
  s.description = "Provides a cross-platform ability to intercept all exceptions as they are raised."

  s.files = `git ls-files`.split("\n")
  s.extensions = "ext/extconf.rb"
  s.require_path = "lib"

  s.add_development_dependency 'rake'
end
