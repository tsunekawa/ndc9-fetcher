$:.unshift File.expand_path("./lib")
require 'bundler'

case ENV['RACK_ENV']
when 'test'
  Bundler.require(:default, :test)
when 'development'
  Bundler.require(:default, :development)
else
  Bundler.require(:default)
end

require 'ndc9_fetcher/ndc9'
require 'ndc9_fetcher/job_manager'
require './app/app'
require './app/admin_app'

# set up for Redis
if ENV["REDISTOGO_URL"] != nil
  uri = URI.parse(ENV["REDISTOGO_URL"])
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
  $redis = Redis.new host:"127.0.0.1", port:"6379"
end

require 'ndc9_fetcher/ndc9'
require 'ndc9_fetcher/job_manager'
require './app/app'
require './app/admin_app'
