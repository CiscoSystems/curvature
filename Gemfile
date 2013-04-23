source 'https://rubygems.org'
gem 'rails', '3.2.8'
gem 'sqlite3'
gem 'json'

# This currently assumes that the intern_incubator repo has also been pulled into the parent directory
# Will be updated when ropenstack is made publicly available
gem 'ropenstack', :path => "../intern-incubator/ropenstack"

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

gem 'socky-authenticator'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
end

# Use unicorn as the app server
gem 'unicorn'
