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
    cache = params[:cache]=="true"

    if cache and $redis.exists isbn then
      ndc9 = $redis.get isbn
    else
      ns   = NDLSearch::NDLSearch.new
      ndc9 = ns.search(:isbn=>isbn).items.first.ndc
      $redis.set isbn, ndc9
    end

    content_type 'application/json'
    {
      :isbn => isbn,
      :ndc9 => ndc9.to_s
    }.to_json
  end
  
end
