require 'bundler'
Bundler.require

class NDC9App < Sinatra::Base

  get '/' do
    'hello'
  end
  
end
