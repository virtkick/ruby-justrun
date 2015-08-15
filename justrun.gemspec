Gem::Specification.new do |s|
  s.name = 'justrun'
  s.version = '1.0.2'
  s.date = '2014-08-15'
  s.summary = 'Run command and get live line by line callbacks'
  s.description = 'Wraps popen3 in a nice interface that allows to just run a command and get live stdout and stderr on line by line basis using a callback. Additionally a live chat with a command can be implemented with a buffered non-blocking writer that\'s working out of the box.'
  s.authors = ['Damian Kaczmarek']
  s.email = 'rush@virtkick.com'
  s.files = ['lib/justrun.rb']
  s.homepage = 'http://rubygems.org/gems/justrun'
  s.license = 'MIT'

  s.files = `git ls-files lib`.split($/)
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec', '3.2.0'
  s.add_development_dependency 'rspec-core', '3.2.0'
  s.add_development_dependency 'lorem_ipsum_amet', '0.6.2'
end