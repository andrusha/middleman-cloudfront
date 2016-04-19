# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'middleman-cloudfront/version'

Gem::Specification.new do |s|
  s.name        = 'middleman-cloudfront'
  s.version     = Middleman::CloudFront::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andrey Korzhuev", "Manuel Meurer"]
  s.email       = ["andrew@korzhuev.com"]
  s.homepage    = "https://github.com/andrusha/middleman-cloudfront"
  s.summary     = %q{Invalidate CloudFront cache after deployment to S3}
  s.description = %q{Adds ability to invalidate a specific set of files in your CloudFront cache}

  s.rubyforge_project = "middleman-cloudfront"

  s.files         = `git ls-files -z`.split("\0")
  s.test_files    = `git ls-files -z -- {fixtures,features}/*`.split("\0")
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency 'fog', '~> 1.9'

  s.add_development_dependency 'cucumber', '~> 1.3'
  s.add_development_dependency 'aruba', '~> 0.5'
  s.add_development_dependency 'fivemat', '~> 1.3'
  s.add_development_dependency 'simplecov', '~> 0.8'
  s.add_development_dependency 'rake', '>= 0.9.0'
  s.add_development_dependency 'rspec', '~> 3.0'

  if RUBY_VERSION <= '1.9.2'
    s.add_dependency 'middleman-core', '~> 3.0', '<= 3.2.0'
    s.add_development_dependency 'activesupport', '< 4.0.0'
  else
    s.add_dependency 'middleman-core', '~> 3.0'
  end
end
