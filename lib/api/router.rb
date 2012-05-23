module Api

  class Router < Goliath::API
    use ::Rack::ContentLength
    use Goliath::Rack::Heartbeat, { :path => '/ping', :response => [200, {}, []] }
    use Goliath::Rack::Tracer, 'X-Tracer'
    use Goliath::Rack::Params
    use Goliath::Rack::DefaultMimeType
    use Goliath::Rack::Validation::RequiredParam, :key => %w(_apikey)
    use Goliath::Rack::BarrierAroundwareFactory, Api::ApiAuthBarrier
    include ApiHelper

    def on_headers(env, headers)
      env.logger.info 'new request: ' + headers.inspect
      env['client-headers'] = headers
    end

    def response(env)
      start_time = Time.now.to_f
      resp = API.call(env)
      process_time = Time.now.to_f - start_time
      record(process_time, resp, env)
      resp
    end

  end
end
