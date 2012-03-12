module Api
  class ApiStatus
    ENDPOINT = '/status'

    attr_accessor :env, :params

    def initialize(env, params)
      self.env      = env
      self.params   = params
    end

    def method_router
      send("#{params['method']}_method".to_sym, params) rescue raise "Method #{params['method']} not found."
    end

    def environment_method(params)
      response = {:env => Goliath.env, :method => params['method']}
      [200, {}, response]
    end

  end
end
