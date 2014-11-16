require './test/test_helper'
require 'minitest/unit'

class TestNDC9 < Minitest::Test

  def setup
    @ndc9 = ::Ndc9Fetcher::NDC9.new
  end

  def teardown
    @ndc9 = nil
  end
 
  def test_fetch
    assert_respond_to @ndc9, :fetch
  end

  def multi_fetch
    assert_respond_to @ndc9, :multi_fetch
  end

end
