# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/upload_to_qmobile/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-upload_to_qmobile'
  spec.version       = Fastlane::UploadToQmobile::VERSION
  spec.author        = %q{icyleaf}
  spec.email         = %q{icyleaf.cn@gmail.com}

  spec.summary       = %q{Upload a mobile app to qmobile}
  spec.homepage      = "https://github.com/icyleaf/fastlane-plugin-upload_to_qmobile"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'qyer-mobile-app', '~> 0.8.5'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'fastlane', '>= 1.111.0'
end
