# frozen_string_literal: true

require_relative "lib/rack_spa"

Gem::Specification.new do |s|
  s.name = "rack-spa"
  s.version = RackSpa::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Rack middlewares to make building and serving a Single Page App from a Ruby Rack app easy."
  s.author = "Lithic Tech"
  s.email = "hello@lithic.tech"
  s.homepage = "https://github.com/lithictech/rack-spa"
  s.licenses = "MIT"
  s.required_ruby_version = ">= 3.1.0"
  s.description = <<~DESC
    Rack middlewares to make building and serving a Single Page App from a Ruby Rack app easy.
  DESC
  s.metadata["rubygems_mfa_required"] = "true"
  s.files = Dir["lib/**/*.rb"]
  s.add_dependency("nokogiri", "~> 1.10")
  s.add_dependency("rack", ">= 2.0")
  s.add_development_dependency("rackup", "~> 2.1")
  s.add_development_dependency("rspec", "~> 3.10")
  s.add_development_dependency("rspec-core", "~> 3.10")
  s.add_development_dependency("rspec-temp_dir")
  s.add_development_dependency("rubocop", "~> 1.25.1")
  s.add_development_dependency("rubocop-performance", "~> 1.13.3")
  s.add_development_dependency("simplecov", "~> 0")
  s.add_development_dependency("timecop")
end
