ENV['RACK_ENV'] = 'test'
require_relative '../config/boot'
require 'minitest/autorun'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end
