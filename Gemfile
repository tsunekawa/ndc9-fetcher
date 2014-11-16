source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib', require: ["sinatra/respond_with", "sinatra/content_for"]
gem 'redis'
gem 'thin'
gem 'nokogiri'
gem 'lisbn'

gem 'bundler', require: [
  "open-uri",
  "json"
]

group :test do
  gem 'rake'
  gem 'vcr'
  gem 'webmock'
  gem 'minitest', require: [
    'minitest/autorun',
    'rack/test'
  ]
  gem 'minitest-reporters', require: ["minitest/reporters"]
end
