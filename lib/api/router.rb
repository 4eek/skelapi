module Api

  # TODO: Split this into seprate files and see if it still works.
  class MyAPI < Grape::API

    version 'v1', :using => :path
    format :json

    resource 'status' do
      # http://0.0.0.0:9000/v1/status/
      get "/" do
        {:got => "here", :now => "here"}
        # ApiStatus.new(env, params).method_router
      end
    end

  end

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
      resp = MyAPI.call(env)
      process_time = Time.now.to_f - start_time
      record(process_time, resp, env)
      resp
    end

    # not_found do
    #   run PageNotFoundController.new
    # end

  end
end
