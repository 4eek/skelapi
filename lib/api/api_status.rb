module Api
  class ApiStatus
    ENDPOINT = '/status'

    attr_accessor :env, :params

    def initialize(env, params)
      self.env      = env
      self.params   = params
    end

    def get
      response = {:env => Goliath.env}
      [200, {}, response]
    end

  end
end
