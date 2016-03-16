# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-rancher/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-rancher'
  spec.version       = VagrantPlugins::Rancher::VERSION
  spec.authors       = ['nextrevision']
  spec.email         = ['notarobot@nextrevision.net']

  spec.summary       = 'Vagrant plugin to bootstrap a Rancher environment.'
  spec.description   = 'Vagrant plugin to install a Rancher server and agents on all vagrant guests.'
  spec.homepage      = 'https://github.com/nextrevision/vagrant-rancher'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
end
