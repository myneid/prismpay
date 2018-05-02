# add gems lib directory to the front of the load path
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "prismpay/version"

Gem::Specification.new do |gem|
  gem.name = "prismpay"
  gem.platform = Gem::Platform::RUBY
  gem.summary = "Provides an interface to Prismpay web services"
  gem.description = "Provide an interface to Prismpay web services, and creates an ActiveMerchant wrapper for PrismPay web services"
  gem.version = PrismPay::VERSION::STRING
  gem.authors = ["Ryan Nash"]
  gem.email = "rnash@tnsolutions.com"
  gem.homepage = "http://development.compassagile.com"
  gem.files = Dir["{lib}/**/*"] + ["README.md"]
  gem.test_files = Dir["spec/**/*"]
  
  gem.add_dependency 'activemerchant'
  gem.add_dependency 'savon'
end

