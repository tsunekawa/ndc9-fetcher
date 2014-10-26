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
  
  ###########################################
  # Custion Exception
  ###########################################
  
  class InvalidISBNError < StandardError; end
  error InvalidISBNError do
    status 400
    message = "入力されたISBNが間違っています。(ISBN: #{env['sinatra.error'].message})"

    respond_to do |f|
      f.html { erb :error, locals: {:message=>message, :status=>400} }
      f.txt  { "error 400 : #{message}" }
      f.json { {:status=>"400", :message=>"error 400 : #{message}"}.to_json }
    end
  end

  class MissingISBNError < StandardError; end
  error MissingISBNError do
    status 400
    message = "入力データが空です。"

    respond_to do |f|
      f.html { erb :error, locals: {:message=>message, :status=>400} }
      f.txt  { "error 400 : #{message}" }
      f.json { {:status=>"400", :message=>"error 400 : #{message}"}.to_json }
    end
  end

  class InvalidMediaType < StandardError; end
  error InvalidMediaType do
    status 406
    message = "#{env['sinatra.error'].message} は現在、入力フォーマットしてサポートしていません。"

    respond_to do |f|
      f.html { erb :error, locals: {:message=>message, :status=>406} }
      f.txt  { "error 406 : #{message}" }
      f.json { {:status=>"406", :message=>"error 406 : #{message}"}.to_json }
    end
  end

  class RequestIDNotFoundError < StandardError; end
  error RequestIDNotFoundError do
    status 404
    message = "入力されたリクエストIDは存在しないか、既に削除されました。(入力されたリクエストID: #{env['sinatra.error'].message}"

    respond_to do |f|
      f.html { erb :error, locals: {:message=>message, :status=>404} }
      f.txt  { "error 404 : #{message}" }
      f.json { {:status=>"404", :message=>"error 404 : #{message}"}.to_json }
    end
  end

  ###########################################
  # Routing
  ###########################################
 
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

    raise InvalidISBNError, isbn unless Lisbn.new(isbn).valid?

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
      raise InvalidMediaType, request.media_type
    end

    # validate input data
    if data["isbn"].size <= 0 then
      raise MissingISBNError
    end
    else
      error_isbns = data["isbn"].map{|isbn| Lisbn.new(isbn).valid? ? nil : isbn }.compact
      raise InvalidISBNError, error_isbns.join(",") unless error_isbns.empty?
    end

    # generate request_id
    request_id = NDC9.bulk_request(data["isbn"], {:cache=>cache})

    # delay fetching ndc9 with EventMachine
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
    raise RequestIDNotFoundError unless NDC9.bulk_request_exists? params["request_id"]

    request_id = params["request_id"]
    result = NDC9.bulk_get(request_id)

    if result.nil? then
      status 102 # Processing
      message = "Please wait...now processing"
      respond_to do |f|
        f.html { erb :'bulk_processing.html', locals: {:request_id=>request_id} }
        f.json { {:status=>102, :message=>message, :request_id=>request_id}.to_json }
        f.txt  { "#{message} (request ID: #{request_id})" }
      end
    else
      status 200 # OK
      respond_to do |f|
        f.html { erb :'bulk_get.html', locals: {:result=>result, :request_id=>params["request_id"]} }
        f.json { result.to_json }
        f.txt  { result.to_a.unshift(["isbn", "ndc9"]).map{|i| i.join("\t")}.join("\n") }
      end
    end
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
