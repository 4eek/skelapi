# require 'ruby-debug' # *** Comment out when not in use ***
require 'pathname'
require 'em-mongo'
require 'em-http'
require 'em-synchrony/em-http'
require 'em-synchrony/em-mongo'
require 'yajl/json_gem'
require 'cobravsmongoose'

require 'api/version'
require 'api/api_helper'

module Api
  extend self

  class ApiError < StandardError; end

  attr_accessor :root_path,
                :lib_path,
                :env,
                :logger,
                :settings,
                :db

  def configure(env)
    @env      = env
    @logger   = env.logger
    @settings = env.config[:settings]
    @db = env.config['db']
  end

end

Api.root_path  = Pathname.new(File.expand_path('../..', __FILE__))
Api.lib_path   = Api.root_path.join('lib/api')

# Load AuthBarrier
require 'api/api_auth_barrier'

# Load models
Dir[Api.lib_path.join('models').to_s+'/*.rb'].each {|f| require f }

# Load controllers
Dir[Api.lib_path.join('controllers/**').to_s+'/*.rb'].each {|f| require f }

# Load Router
require 'api/router'

