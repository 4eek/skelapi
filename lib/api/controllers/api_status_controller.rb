module Api

  class API < Grape::API

    resource 'status' do
      # http://0.0.0.0:9000/v1/status
      get "/" do
        ApiStatus.new(env, self).get
      end
    end

  end

end
