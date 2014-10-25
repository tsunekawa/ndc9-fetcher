class NDC9App < Sinatra::Base
  register Sinatra::RespondWith

  # resolve url extention
  before /\..+$/ do
    case request.url
    when /\.txt$/
      request.accept.unshift('text/plain')
      request.path_info = request.path_info.gsub(/.txt$/,'')
    when /\.html$/
      request.accept.unshift('text/html')
      request.path_info = request.path_info.gsub(/.html$/,'')
    when /\.json$/
      request.accept.unshift('application/json')
      request.path_info = request.path_info.gsub(/.json$/,'')
    when /\.xml$/
      request.accept.unshift('application/xml')
      request.path_info = request.path_info.gsub(/.xml$/,'')
    when /\.rdf$/
      request.accept.unshift('application/rdf+xml')
      request.path_info = request.path_info.gsub(/.rdf$/,'')
    else
      error 406
    end
  end

  get '/' do
    erb :index
  end

  get '/bulk' do
    erb :bulk
  end

  # return a NDC9 code number which correspond to the ISBN
  get '/v1/isbn/:isbn' do
    isbn =  params[:isbn].gsub("-","")
    cache = (params[:cache] || "true")=="true"

    ndc9 = NDC9.fetch(isbn, {:cache=>cache})

    respond_to do |f|
      f.html { ndc9.to_s }
      f.xml  { erb :'isbn.rdf', locals: {:isbn=>isbn, :ndc9=>ndc9} }
      f.on('application/rdf+xml') { erb :'isbn.rdf', locals: {:isbn=>isbn, :ndc9=>ndc9} }
      f.json { {:isbn=>isbn, :ndc9=>ndc9.to_s}.to_json }
      f.txt  { ndc9.to_s }
    end
  end

  post '/v1/isbn/bulk' do
    cache = (params[:cache] || "true")=="true"

    case request.media_type
    when 'application/json'
      data = JSON.parse request.body.read
    when 'text/plain'
      data = {"isbn"=>request.body.split("\n")}
    when 'application/x-www-form-urlencoded'
      data = {"isbn"=>params["isbn"].gsub("\r","").split("\n")}
    else
      error 406
    end

    if data["isbn"].size <= 0 then
      error 400
    end

    request_id = NDC9.bulk_request(data["isbn"], {:cache=>cache})

    EM.defer do
      NDC9.bulk_fetch(request_id)
    end

    respond_to do |f|
      f.html { redirect "/v1/isbn/bulk/#{request_id}" }
      f.txt  { "request id: #{request_id}" }
      f.json { {:request_id=>request_id}.to_json }
    end
  end

  get '/v1/isbn/bulk/:request_id' do
    halt 404 unless NDC9.bulk_request_exists? params["request_id"]

    result = NDC9.bulk_get(params["request_id"])
    if result.nil? then
      status 102 # Processing
      "Please wait...now processing"
    else
      status 200 # OK
      respond_to do |f|
        f.html { erb :'bulk_get.html', locals: {:result=>result} }
        f.json { result.to_json }
        f.txt  { result.to_a.unshift(["isbn", "ndc9"]).map{|i| i.join("\t")}.join("\n") }
      end
    end
  end

  helpers do
    def root_path
      "#{request.scheme}://#{request.host_with_port}"
    end
  end
end
