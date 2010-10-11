Gem::Specification.new do |s|
  s.name = %q{epsilon}
  s.version = '0.0.0'
  s.summary = %q{API to DREAMmail Real Time Messaging}
  s.description = %q{API to DREAMmail Real Time Messaging}

  s.files = [
    'README',
    'Rakefile',
    'init.rb',
    'lib/epsilon.rb',
    'lib/epsilon/api.rb'
  ]
  s.require_paths = ['lib']
  s.test_files = ['test/epsilon_test.rb']
  s.add_dependency(%q<builder>, [">= 2.1.2"])
  s.add_dependency(%q<libxml-ruby>, [">= 1.1.4"])
end
