module Api
  class Router < Goliath::API
    use ::Rack::ContentLength
    use Goliath::Rack::Heartbeat, { :path => '/ping', :response => [200, {}, []] }

    post ApiStatus::ENDPOINT, ApiStatusController

    not_found do
      run PageNotFoundController.new
    end

  end
end
