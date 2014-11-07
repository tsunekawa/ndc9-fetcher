require './config/boot'
require './app/app'
require './app/admin_app'

if ENV["ADMIN_USERNAME"].nil? or ENV["ADMIN_PASSWORD"].nil? then
  run Ndc9Fetcher::App
else
  run Rack::URLMap.new({
    "/" => Ndc9Fetcher::App,
    "/admin" => Ndc9Fetcher::AdminApp
  })
end

# processing background job
EM::defer do
  job_manager = Ndc9Fetcher::JobManager.new
  loop do
    sleep 3
    job_manager.random_exec
  end
end
