require 'bundler'
Bundler.require

# set up for Redis
if ENV["REDISTOGO_URL"] != nil
  uri = URI.parse(ENV["REDISTOGO_URL"])
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
  $redis = Redis.new host:"127.0.0.1", port:"6379"
end

require_relative '../lib/ndc9'
require_relative '../lib/job_manager'
require_relative '../app'
require_relative '../admin_app'
