require 'bundler'
Bundler.require

class NDC9App < Sinatra::Base

  get '/' do
    'hello'
  end

  get '/v1/isbn/:isbn' do
    isbn = params[:isbn]
    ns   = NDLSearch::NDLSearch.new
    ndc9 = ns.search(:isbn=>isbn).items.first.ndc

    content_type 'application/json'
    {
      :isbn => isbn,
      :ndc9 => ndc9.to_s
    }.to_json
  end
  
end
