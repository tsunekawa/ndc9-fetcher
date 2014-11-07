class NDC9
  class InvalidISBNError < StandardError; end
  attr_reader :redis

  def initialize(opt={})
    setup_redis(opt[:redis])
    @cache = (opt[:cache] || true)
  end

  def use_cache?
    @cache & true
  end

  def last_request
    redis.get "last_request"
  end

  def fetch(isbn_str, opt={})
    isbn = Lisbn.new(isbn_str)
    raise InvalidISBNError, isbn unless isbn.valid?

    cache = (opt["cache"] || use_cache?)
    cache(isbn, {:cache=>cache}) do
        request_wait
        source = open("http://iss.ndl.go.jp/api/opensearch?dpid=iss-ndl-opac&isbn=#{isbn.isbn13.to_s}&mediatype=1").read
        doc    = Nokogiri::XML.parse(source)
        doc.xpath("//channel/item/dc:subject[@xsi:type='dcndl:NDC9']/text()").to_s 
    end
  end

  def multi_fetch(isbn_list, opt={})
    raise ArgumentError, "isbn_list should be Array" unless isbn_list.instance_of? Array
    isbn_list.map do |isbn|
      [isbn, fetch(isbn, opt)]
    end
  end

  private

  def request_wait
    unless last_request.nil?
      time = (Time.now - last_request)
      if  tiem < 1.0 then
        sleep (1.0-time)
      end
    end
  end

  def setup_redis(arg)
    if arg.instance_of? String then
      redis_uri = URI.parse( (opt[:redis] || "redis://127.0.0.1:6379") )
      @redis = Redis.new(:host=>uri.host, :port=>uri.port, :password => uri.password)
    elsif arg.instance_of? Redis then
      @redis = arg
    else
      @redis = Redis.new host:"127.0.0.1", port:"6379"
    end
  end

  # cache and return value with Redis
  def cache(name, opts={}, &block)
    cache = opts[:cache]
    if cache then
      if redis.exists name then
        redis.get name
      else
        value = yield
        redis.set name, value
        value
      end
    else
      value = yield
      redis.set "last_request", Time.now
    end
  end

end
