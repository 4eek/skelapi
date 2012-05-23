# Tracks and enforces account and rate limit policies.
#
# On GET or HEAD requests, it proxies the request and gets account/usage info
# concurrently; authorizing the account doesn't delay the response.
#
# On a POST or other non-idempotent request, it checks the account/usage info
# *before* allowing the request to fire. This takes longer, but is necessary and
# tolerable.
#
# The magic of BarrierAroundware:
#
# 1. In pre_process (before the request):
#    * validate an apikey was given; if not, raise (returning directly)
#    * launch requests for the account and rate limit usage
#
# 2. On a POST or other non-GET non-HEAD, we issue `perform`, which barriers
#    (allowing other requests to proceed) until the two pending requests
#    complete. It then checks the account exists and is valid, and that the rate
#    limit is OK
#
# 3. If the auth check fails, we raise an error (later caught by a safely{}
#    block and turned into the right 4xx HTTP response.
#
# 4. If the auth check succeeds, or the request is a GET or HEAD, we return
#    Goliath::Connection::AsyncResponse, and BarrierAroundwareFactory passes the
#    request down the middleware chain
#
# 5. post_process resumes only when both proxied request & auth info are complete
#    (it already has of course in the non-lazy scenario)
#
# 6. If we were lazy, the post_process method now checks authorization
#
class ApiAuthBarrier
  include Goliath::Rack::BarrierAroundware
  include Goliath::Validation
  attr_reader   :db
  attr_accessor :account_info, :usage_info

  # time period to aggregate stats over, in seconds
  TIMEBIN_SIZE = 60 * 60

  class MissingApikeyError     < BadRequestError   ; end
  class RateLimitExceededError < ForbiddenError    ; end
  class InvalidApikeyError     < UnauthorizedError ; end
  class InvalidIpError         < UnauthorizedError ; end

  def initialize(env)
    @db = env.db
    super(env)
  end

  def pre_process
    env.trace('pre_process_beg')
    validate_apikey!

    # the results of the first deferrable will be set right into account_info (and the request into successes)
    enqueue_mongo_request(:account_info, { :_id => apikey   })
    enqueue_mongo_request(:usage_info,   { :_id => usage_id })
    maybe_fake_delay!

    # On non-GET non-HEAD requests, we have to check auth now.
    unless lazy_authorization?
      perform     # yield execution until user info has arrived
      charge_usage
      check_authorization!
    end

    env.trace('pre_process_end')
    return Goliath::Connection::AsyncResponse
  end

  def post_process
    env.trace('post_process_beg')
    # [:account_info, :usage_info, :status, :headers, :body].each{|attr| env.logger.info(("%23s\t%s" % [attr, self.send(attr).inspect[0..200]])) }

    # We have to check auth now, we skipped it before
    if lazy_authorization?
      charge_usage
      check_authorization!
    end

    inject_headers

    env.trace('post_process_end')
    [status, headers, body]
  end

  def lazy_authorization?
    (env['REQUEST_METHOD'] == 'GET') || (env['REQUEST_METHOD'] == 'HEAD')
  end

  if defined?(EM::Mongo::Cursor)
    # em-mongo > 0.3.6 gives us a deferrable back. nice and clean.
    def enqueue_mongo_request(handle, query)
      enqueue handle, db.collection(handle).afirst(query)
    end
  else
    # em-mongo <= 0.3.6 makes us fake a deferrable response.
    def enqueue_mongo_request(handle, query)
      enqueue_acceptor(handle) do |acc|
        db.collection(handle).afind(query){|resp| acc.succeed(resp.first) }
      end
    end
  end

  # Fake out a delay in the database response if auth_db_delay is given
  def maybe_fake_delay!
    if (auth_db_delay = env.params['auth_db_delay'].to_f) > 0
      enqueue_acceptor(:sleepy){|acc| EM.add_timer(auth_db_delay){ acc.succeed } }
    end
  end

  # def accept_response(handle, *args)
  #   env.trace("received_#{handle}")
  #   super(handle, *args)
  # end

  # ===========================================================================

  def check_authorization!
    check_apikey!
    check_ip!
    check_rate_limit!
  end

  def validate_apikey!
    if apikey.to_s.empty?
      raise MissingApikeyError
    end
  end

  def check_apikey!
    unless account_info && (account_info['active'] == true)
      raise InvalidApikeyError
    end
  end

  def check_ip!
    unless account_info && account_info['ips']
      raise InvalidIpError, "Invalid remote address configuration."
    end
    unless account_info && (account_info['ips'].include?(ip) || account_info['ips'].include?('0.0.0.0'))
      raise InvalidIpError, "Invalid remote address."
    end
  end

  def check_rate_limit!
    self.usage_info ||= {}
    rate  = usage_info['calls'].to_i + 1
    limit = account_info['max_call_rate'].to_i
    return true if rate <= limit
    raise RateLimitExceededError, "Your request rate (#{rate}) is over your limit (#{limit})"
  end

  def charge_usage
    EM.next_tick do
      safely(env){ db.collection(:usage_info).update({ :_id => usage_id },
                                                         { '$inc' => { :calls   => 1 } }, :upsert => true) }
    end
  end

  def inject_headers
    headers.merge!({
      'X-RateLimit-MaxRequests' => account_info['max_call_rate'].to_s,
      'X-RateLimit-Requests'    => usage_info['calls'].to_i.to_s,
      'X-RateLimit-Reset'       => timebin_end.to_s,
    })
  end

  # ===========================================================================

  def apikey
    env.params['_apikey']
  end

  def usage_id
    "#{apikey}-#{timebin}"
  end

  def ip
    if addr = env['HTTP_X_FORWARDED_FOR']
      (addr.split(',').grep(/\d\./).first || env['REMOTE_ADDR']).to_s.strip
    else
      env['REMOTE_ADDR']
    end
  end

  def timebin
    @timebin ||= timebin_beg
  end

  def timebin_beg
    ((Time.now.to_i / TIMEBIN_SIZE).floor * TIMEBIN_SIZE)
  end

  def timebin_end
    timebin_beg + TIMEBIN_SIZE
  end
end
