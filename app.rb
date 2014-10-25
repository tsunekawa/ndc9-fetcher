require 'bundler'
Bundler.require

# set up for Redis
if ENV["REDISTOGO_URL"] != nil
  uri = URI.parse(ENV["REDISTOGO_URL"])
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
  $redis = Redis.new host:"127.0.0.1", port:"6379"
end

module NDC9
  def self.last_request
    $redis.get "last_request"
  end

  def self.fetch(isbn, opt={})
    cache = (opt["cache"] || true)
    self.cache(isbn, {:cache=>cache}) do
        unless self.last_request.nil?
          time = (Time.now - self.last_request)
          if  tiem < 1.0 then
            sleep (1.0-time)
          end
        end

        source = open("http://iss.ndl.go.jp/api/opensearch?dpid=iss-ndl-opac&isbn=#{isbn}&mediatype=1").read
        doc    = Nokogiri::XML.parse(source)
        doc.xpath("//channel/item/dc:subject[@xsi:type='dcndl:NDC9']/text()").to_s 
    end
  end

  def self.multi_fetch(isbn_list, opt={})
    raise ArgumentError, "isbn_list should be Array" unless isbn_list.instance_of? Array
    isbn_list.map do |isbn|
      [isbn, self.fetch(isbn, opt)]
    end
  end

  def self.bulk_request(isbn_list, opt={})
    raise ArgumentError, "isbn_list should be Array" unless isbn_list.instance_of? Array
    request_id = Digest::SHA1.hexdigest(isbn_list.to_s)

    $redis.multi do
      isbn_list.each do |isbn|
        $redis.lpush "request:#{request_id}", isbn
      end
    end
    request_id
  end

  def self.bulk_request_exists?(request_id)
    $redis.exists("request:#{request_id}") or $redis.exists("result:#{request_id}")
  end

  def self.bulk_fetch(request_id)
    key = "request:#{request_id}"
    raise unless $redis.exists key

    while $redis.llen(key) > 0 do
      isbn = $redis.lindex(key, 0)
      ndc9 = self.fetch(isbn)
      $redis.multi do
        $redis.lpop key
        $redis.hset "result:#{request_id}", isbn, ndc9
      end
    end

    $redis.expire "result:#{request_id}", 43200 # 6 hours
    $redis.del "request:#{request_id}"

    true
  end

  def self.bulk_get(request_id)
    if !($redis.exists "request:#{request_id}") and $redis.exists "result:#{request_id}"
      $redis.hgetall "result:#{request_id}"
    else
      nil
    end
  end

  # cache and return value with Redis
  def self.cache(name, opts={}, &block)
    cache = opts[:cache]
    if cache then
      if $redis.exists name then
        $redis.get name
      else
        value = yield
        $redis.set name, value
        value
      end
    else
      value = yield
      $redis.set "last_request", Time.now
    end
  end
end

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

    request_id = NDC9.bulk_request(data["isbn"], {:cache=>cache})

    EM.defer do
      NDC9.bulk_fetch(request_id)
    end

    redirect "/v1/isbn/bulk/#{request_id}"
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
        f.json { result.to_json }
        f.txt  { result.to_a.unshift(["isbn", "ndc9"]).map{|i| i.join("\t")}.join("\n") }
      end
    end
  end

  helpers do
    def root_path
      "#{request.scheme}://#{request.host_with_port}/"
    end
  end
end
