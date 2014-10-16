# coding: utf-8

Gem::Specification.new do |spec|

  spec.name          = 'rack-test-poc'
  spec.version       = File.read(File.join(File.dirname(__FILE__),'VERSION')).split("\n")[0].chomp.gsub(' ','')
  spec.authors       = ['Adam Luzsi']
  spec.email         = ['adamluzsi@gmail.com']

  spec.description   = [
      'rack/test based poc file generator,',
      'this will make you able to export any',
      'data that traveled through the test,',
      'and be able to create poc file with that.',
      'It is even useful for creating integration',
      'test that is based on your api endpoints,',
      'because the export file will be serialized',
      'into a yaml file that contain all the',
      'endpoints that you just tested, and',
      'it\'s inputs and outputs'

  ].join(' ')

  spec.summary       = 'rack/test based poc file generator'

  spec.homepage      = "https://github.com/adamluzsi/#{__FILE__.split(File::Separator).last.split('.').first}"
  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'rack-test'

end
