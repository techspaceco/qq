Gem::Specification.new do |s|
  s.name          = 'qq'
  s.version       = '0.2.4'
  s.licenses      = ['MIT']
  s.summary       = 'Improved pp debugging.'
  s.description   = 'Improved puts debugging output for busy Ruby programmers.'
  s.authors       = ['Shane Hanna']
  s.email         = 'shane.hanna@gmail.com'
  s.files         = ['lib/qq.rb']
  s.require_paths = ['lib']
  s.homepage      = 'https://github.com/techspaceco/qq'
  s.bindir        = 'bin'

  s.executables << 'qq'

  s.add_runtime_dependency('parser', ['~> 2.3'])
  s.add_runtime_dependency('unparser', ['~> 0.2'])
end
