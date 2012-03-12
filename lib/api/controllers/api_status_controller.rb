module Api
  class ApiStatusController < Goliath::API
    use Goliath::Rack::Tracer, 'X-Tracer'
    use Goliath::Rack::Params
    use Goliath::Rack::DefaultMimeType
    use Goliath::Rack::Render, 'json'
    use Goliath::Rack::Validation::RequiredParam, :key => %w(_apikey)
    use Goliath::Rack::BarrierAroundwareFactory, Api::ApiAuthBarrier
    include ApiHelper

    def response(env)
      ApiStatus.new(env, params).method_router
    end
  end
end
