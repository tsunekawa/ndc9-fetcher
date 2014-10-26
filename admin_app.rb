class AdminApp < Sinatra::Base
  register Sinatra::RespondWith
  helpers Sinatra::ContentFor

  get '/' do
    job_manager = JobManager.new
    erb :admin, locals: {
      :request_id_list    => job_manager.request_id_list,
      :processing_id_list => job_manager.processing_id_list,
      :result_id_list     => job_manager.result_id_list
    }
  end

  def self.new(*)
    app = Rack::Auth::Digest::MD5.new(super) do |username|
      {ENV["ADMIN_USERNAME"] => ENV["ADMIN_PASSWORD"]}[username]
    end
    app.realm = 'Protected Area'
    app.opaque = 'secretkey'
    app
  end

  ###########################################
  # Helper Methods
  ###########################################

  helpers do
    def root_path
      "#{request.scheme}://#{request.host_with_port}"
    end
  end
end
