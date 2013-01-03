Gem::Specification.new do |s|
  s.name        = 'kunoichi'
  s.version     = '0.0.1'
  s.homepage    = 'https://github.com/xstasi/kunoichi'
  s.authors     = [ 'Alessandro Grassi' ] 
  s.email       = ['alessandro@aggro.it']

  s.summary     = 'Process privilege escalation monitor'
  s.description = "A Ruby rewrite of Tom Rune Flo's Ninja, a privilege escalation monitor."

  s.files       = Dir.glob('lib/**/*.rb')
  s.executables << 'kunoichi'

  s.add_runtime_dependency 'logger', '~> 1.2.8'
  s.add_runtime_dependency 'syslog-logger', '~> 1.6.8'
end
  
