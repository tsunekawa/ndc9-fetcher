require './test/test_helper'

include Rack::Test::Methods

def app
  Ndc9Fetcher::App
end

describe 'Ndc9Fetcher App' do

  it 'get / returns OK' do
    get '/'
    assert last_response.ok?
  end

end
