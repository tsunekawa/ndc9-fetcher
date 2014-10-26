class RequestIDNotFoundError < StandardError; end
class ProcessingException < StandardError; end

class JobManager
  BULK_EXPIRE = 43200 # 6 hours

  def request_id_list
    $redis.keys(request_key_of("*")).map{|key| key.gsub("request:","")}
  end

  def processing_id_list
    $redis.keys(processing_key_of("*")).map{|key| key.gsub("processing:","")}
  end

  def result_id_list
    $redis.keys(result_key_of("*")).map{|key| key.gsub("result:","")}
  end

  def random_exec
    if request_id_list.empty? then
      nil
    else
      request_id = request_id_list.sample.scan(/^request:(.+)$/).flatten.first
      bulk_fetch(request_id)
      request_id
    end
  end

  def bulk_request(isbn_list, opt={})
    raise ArgumentError, "isbn_list should be Array" unless isbn_list.instance_of? Array
    request_id = Digest::SHA1.hexdigest(isbn_list.sort.to_s)

    unless $redis.exists request_key_of(request_id) then
      $redis.multi do
        isbn_list.each do |isbn|
          $redis.lpush request_key_of(request_id), isbn
        end
      end
    end

    request_id
  end

  def bulk_request_exists?(request_id)
    $redis.exists(request_key_of(request_id)) or $redis.exists(result_key_of(request_id)) or $redis.exists(processing_key_of(request_id))
  end

  def bulk_fetch(request_id)
    raise ::RequestIDNotFound unless $redis.exists request_key_of(request_id)
    $redis.renamenx request_key_of(request_id), processing_key_of(request_id)

    while $redis.llen(processing_key_of(request_id)) > 0 do
      isbn = $redis.lindex(processing_key_of(request_id), 0)
      ndc9 = NDC9.fetch(isbn)
      $redis.multi do
        $redis.lpop processing_key_of(request_id)
        $redis.hset result_key_of(request_id), isbn, ndc9
      end
    end

    $redis.expire result_key_of(request_id), BULK_EXPIRE
    $redis.del processing_key_of(request_id)

    true
  end

  def bulk_get(request_id)
    if $redis.exists(request_key_of(request_id)) or $redis.exists(processing_key_of(request_id)) then
      nil
    elsif $redis.exists(result_key_of(request_id)) then
      $redis.hgetall "result:#{request_id}"
    else
      raise RequestIDNotFoundError, reauest_id
    end
  end

  private

  def request_key_of(request_id)
    "request:#{request_id}"
  end

  def processing_key_of(request_id)
    "processing:#{request_id}"
  end

  def result_key_of(request_id)
    "result:#{request_id}"
  end

  def error_key_of(request_id)
    "error:#{request_id}"
  end

end
