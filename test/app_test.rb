require './test/test_helper'

describe 'Ndc9Fetcher App' do
  include Rack::Test::Methods

  def app
    Ndc9Fetcher::App
  end

  it 'get / returns OK' do
    get '/'
    assert last_response.ok?
  end

end
