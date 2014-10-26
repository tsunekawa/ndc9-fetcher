require './config/boot'

if ENV["ADMIN_USERNAME"].nil? or ENV["ADMIN_PASSWORD"].nil? then
  run NDC9App
else
  run Rack::URLMap.new({
    "/" => NDC9App,
    "/admin" => AdminApp
  })
end

# processing background job
EM::defer do
  job_manager = JobManager.new
  loop do
    sleep 3
    job_manager.random_exec
  end
end
