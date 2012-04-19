module Api
  class ApiStatus
    ENDPOINT = '/status'

    attr_accessor :env, :params

    def initialize(env, params)
      self.env      = env
      self.params   = params
    end

    def method_router
      send("#{params['method']}_method".to_sym, params) rescue raise "Method #{params['method']||'EMPTY_METHOD'} not found."
    end

    def environment_method(params)
      env.trace('method_beg')
      EM::Synchrony.sleep(5) # pretent it's a lot of work
      response = {:env => Goliath.env, :method => params['method']}
      env.trace('method_end')
      [200, {}, response]
    end

  end
end
