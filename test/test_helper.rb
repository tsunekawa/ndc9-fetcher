ENV['RACK_ENV'] = 'test'
require_relative '../config/boot'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end
