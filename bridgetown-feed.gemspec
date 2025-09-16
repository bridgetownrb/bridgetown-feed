# frozen_string_literal: true

require_relative "lib/bridgetown-feed/version"

Gem::Specification.new do |spec|
  spec.name          = "bridgetown-feed"
  spec.version       = Bridgetown::Feed::VERSION
  spec.author        = "Bridgetown Team"
  spec.email         = "maintainers@bridgetownrb.com"
  spec.summary       = "A Bridgetown plugin to generate an Atom feed of your Bridgetown posts"
  spec.homepage      = "https://github.com/bridgetownrb/bridgetown-feed"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|script|spec|features)/!) }
  spec.test_files    = spec.files.grep(%r!^spec/!)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.1.0"

  spec.add_dependency "bridgetown", ">= 1.2.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rss"
  spec.add_development_dependency "nokogiri", "~> 1.6"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-bridgetown", "~> 0.2"
  spec.add_development_dependency "typhoeus", ">= 0.7", "< 2.0"
end
