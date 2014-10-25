module NDC9
  def self.last_request
    $redis.get "last_request"
  end

  def self.fetch(isbn, opt={})
    cache = (opt["cache"] || true)
    self.cache(isbn, {:cache=>cache}) do
        unless self.last_request.nil?
          time = (Time.now - self.last_request)
          if  tiem < 1.0 then
            sleep (1.0-time)
          end
        end

        source = open("http://iss.ndl.go.jp/api/opensearch?dpid=iss-ndl-opac&isbn=#{isbn}&mediatype=1").read
        doc    = Nokogiri::XML.parse(source)
        doc.xpath("//channel/item/dc:subject[@xsi:type='dcndl:NDC9']/text()").to_s 
    end
  end

  def self.multi_fetch(isbn_list, opt={})
    raise ArgumentError, "isbn_list should be Array" unless isbn_list.instance_of? Array
    isbn_list.map do |isbn|
      [isbn, self.fetch(isbn, opt)]
    end
  end

  def self.bulk_request(isbn_list, opt={})
    raise ArgumentError, "isbn_list should be Array" unless isbn_list.instance_of? Array
    request_id = Digest::SHA1.hexdigest(isbn_list.to_s)

    $redis.multi do
      isbn_list.each do |isbn|
        $redis.lpush "request:#{request_id}", isbn
      end
    end
    request_id
  end

  def self.bulk_request_exists?(request_id)
    $redis.exists("request:#{request_id}") or $redis.exists("result:#{request_id}")
  end

  def self.bulk_fetch(request_id)
    key = "request:#{request_id}"
    raise unless $redis.exists key

    while $redis.llen(key) > 0 do
      isbn = $redis.lindex(key, 0)
      ndc9 = self.fetch(isbn)
      $redis.multi do
        $redis.lpop key
        $redis.hset "result:#{request_id}", isbn, ndc9
      end
    end

    $redis.expire "result:#{request_id}", 43200 # 6 hours
    $redis.del "request:#{request_id}"

    true
  end

  def self.bulk_get(request_id)
    if !($redis.exists "request:#{request_id}") and $redis.exists "result:#{request_id}"
      $redis.hgetall "result:#{request_id}"
    else
      nil
    end
  end

  # cache and return value with Redis
  def self.cache(name, opts={}, &block)
    cache = opts[:cache]
    if cache then
      if $redis.exists name then
        $redis.get name
      else
        value = yield
        $redis.set name, value
        value
      end
    else
      value = yield
      $redis.set "last_request", Time.now
    end
  end
end
