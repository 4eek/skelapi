require 'goliath'
# require 'ruby-debug' # *** Comment out when not in use ***
require 'em-mongo'
require 'em-http'
require 'em-synchrony/em-http'
require 'em-synchrony/em-mongo'
require 'yajl/json_gem'

$: << File.expand_path('../..', __FILE__)

# Middleware
require 'middleware/api_auth_barrier'

class Version < Goliath::API
  use ::Rack::ContentLength
  use Goliath::Rack::Heartbeat, { :path => '/status', :response => [200, {}, []] }
  use Goliath::Rack::Tracer, 'X-Tracer'
  use Goliath::Rack::Params
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Render, 'json'
  use Goliath::Rack::Validation::RequiredParam, :key => %w(_apikey)
  use Goliath::Rack::BarrierAroundwareFactory, ApiAuthBarrier

  def response(env)
    [200, {}, env]
  end
end
