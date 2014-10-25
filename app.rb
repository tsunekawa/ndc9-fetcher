require 'bundler'
Bundler.require

if ENV["REDISTOGO_URL"] != nil
  uri = URI.parse(ENV["REDISTOGO_URL"])
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
  $redis = Redis.new host:"127.0.0.1", port:"6379"
end

class NDC9App < Sinatra::Base

  get '/' do
    'hello'
  end

  get '/v1/isbn/:isbn' do
    isbn =  params[:isbn].gsub("-","")
    cache = (params[:cache] || "true")=="true"

    if cache and $redis.exists isbn then
      ndc9 = $redis.get isbn
    else
      result = Nokogiri::XML.parse(
        open("http://iss.ndl.go.jp/api/opensearch?dpid=iss-ndl-opac&isbn=#{isbn}&mediatype=1").read
      )
     
      ndc9 = result.xpath("//channel/item/dc:subject[@xsi:type='dcndl:NDC9']/text()").to_s 
      $redis.set isbn, ndc9
    end

    content_type 'text/plain'
    ndc9.to_s
  end
  
end
