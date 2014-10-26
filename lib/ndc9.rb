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

