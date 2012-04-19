module Api
  class ApiStatus
    ENDPOINT = '/status'

    attr_accessor :env, :params

    def initialize(env, params)
      self.env      = env
      self.params   = params
    end

    def method_router
      begin
        send("#{params['method']}_method".to_sym, params)
      rescue ApiError
        raise
      rescue
        raise "Method #{params['method']||'EMPTY_METHOD'} not found."
      end
    end

    def environment_method(params)
      begin
        env.trace('method_beg')
        # raise Goliath::Validation::Error.new(401, "Invalid param") unless params['some_param'] and params['some_param'] != ''
        EM::Synchrony.sleep(5) # pretent it's a lot of work
        response = {:env => Goliath.env, :method => params['method']}
        env.trace('method_end')
        [200, {}, response]
      rescue Goliath::Validation::Error => e
        raise ApiError, "API Validation: #{e.message}"
      rescue => e
        raise ApiError, "API Exception: MESSAGE:#{e.message} BACKTRACE:#{e.backtrace.join('____')}"
      end
    end

  end
end
