require './config/boot'

run NDC9App

# processing background job
EM::defer do
  job_manager = JobManager.new
  loop do
    sleep 3
    job_manager.random_exec
  end
end
