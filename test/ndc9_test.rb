require './test/test_helper'

describe 'NDC9' do

  before do
    @ndc9 = ::Ndc9Fetcher::NDC9.new
  end

  after do
    @ndc9 = nil
  end

  describe '#fetch' do
    it 'is defined' do
      @ndc9.must_respond_to :fetch
    end

    it 'returns a ndc9 code' do
      VCR.use_cassette 'ndc9/fetch_1' do
        @ndc9.fetch('9784479300342').must_equal '141.5'
      end
    end

    it 'throw InvalidISBNError when first argument is not valid ISBN' do
      lambda { @ndc9.fetch('invalidisbn') }.must_raise ::Ndc9Fetcher::InvalidISBNError
    end

  end

  describe '#multi_fetch' do
    it 'is defined' do
      @ndc9.must_respond_to :multi_fetch
    end
  end

end
