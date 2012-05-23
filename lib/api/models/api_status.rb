module Api
  class ApiStatus

    attr_accessor :env, :params, :endpoint

    def initialize(env, endpoint)
      self.env      = env
      self.params   = env.params
      self.endpoint = endpoint
    end

    def get
      begin
        env.trace('method_beg')
        # raise Goliath::Validation::Error.new(401, "Invalid param") unless params['some_param'] and params['some_param'] != ''
        EM::Synchrony.sleep(5) # pretent it's a lot of work
        response = env
        env.trace('method_end')
        response
      rescue Goliath::Validation::Error => e
        raise ApiError, "API Validation: #{e.message}"
      end
    end

  end
end
