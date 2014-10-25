require 'bundler'
Bundler.require
require 'sinatra/respond_with'

# set up for Redis
if ENV["REDISTOGO_URL"] != nil
  uri = URI.parse(ENV["REDISTOGO_URL"])
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
  $redis = Redis.new host:"127.0.0.1", port:"6379"
end

class NDC9App < Sinatra::Base
  register Sinatra::RespondWith

  # resolve url extention
  before /\.+$/ do
    case request.url
    when /\.txt$/
      request.accept.unshift('text/plain')
      request.path_info = request.path_info.gsub(/.text$/,'')
    when /\.json$/
      request.accept.unshift('application/json')
      request.path_info = request.path_info.gsub(/.json$/,'')
    when /\.xml$/
      request.accept.unshift('application/rdf+xml')
      request.path_info = request.path_info.gsub(/.xml$/,'')
    else
      halt 406
    end
  end

  get '/' do
    erb :index
  end

  # return a NDC9 code number which correspond to the ISBN
  get '/v1/isbn/:isbn' do
    isbn =  params[:isbn].gsub("-","")
    cache = (params[:cache] || "true")=="true"

    ndc9 = cache(isbn, {:cache=>cache}) do
      source = open("http://iss.ndl.go.jp/api/opensearch?dpid=iss-ndl-opac&isbn=#{isbn}&mediatype=1").read
      doc    = Nokogiri::XML.parse(source)
      doc.xpath("//channel/item/dc:subject[@xsi:type='dcndl:NDC9']/text()").to_s 
    end

    respond_to do |f|
      f.html { ndc9.to_s }
      f.xml  { erb :'isbn.rdf', locals: {:isbn=>isbn, :ndc9=>ndc9} }
      f.json { {:isbn=>isbn, :ndc9=>ndc9.to_s}.to_json }
      f.text { ndc9.to_s }
    end
  end

  helpers do
    # cache and return value with Redis
    def cache(name, opts={}, &block)
      cache = opts[:cache]
      if cache then
        if $redis.exists name then
          $redis.get name
        else
          value = yield
          $redis.set name, value
        end
      else
        yield
      end
    end
  end
end

