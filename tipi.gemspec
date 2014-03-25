# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name     = "tipi"
  s.version  = "0.1.0"
  s.date     = "2014-03-25"
  s.summary  = "Resource oriented APIs"
  s.email    = "judofyr@gmail.com"
  s.homepage = "https://github.com/judofyr/tipi"
  s.authors  = ['Magnus Holm']
  
  s.description = s.summary
  
  s.files         = Dir['{test,lib}/**/*']
  s.test_files    = Dir['test/**/*']

  s.add_runtime_dependency('finitio', '0.4.1')
end
