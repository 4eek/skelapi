module Api
  class Router < Goliath::API
    use ::Rack::ContentLength
    use Goliath::Rack::Heartbeat, { :path => '/ping', :response => [200, {}, []] }

    # This will auto create endpoints from files found in the respective HTTP verb controllers directories.
    # NOTE: This is slightly slower than simple invocation. See http://blog.sidu.in/2008/02/loading-classes-from-strings-in-ruby.html
    #
    # POST
    Dir.foreach(Api.lib_path.join('controllers/post').to_s) do |f|
      next if f =~ /^\./
      klass = f.gsub(/_controller.rb$/, '').split('_').map{ |e| e.capitalize }.join
      post "/api/v#{VERSION}#{Kernel.const_get("Api").const_get(klass).const_get("ENDPOINT")}", Kernel.const_get("Api").const_get("#{klass}Controller".to_sym)
    end
    # GET
    Dir.foreach(Api.lib_path.join('controllers/get').to_s) do |f|
      next if f =~ /^\./
      klass = f.gsub(/_controller.rb$/, '').split('_').map{ |e| e.capitalize }.join
      get "/api/v#{VERSION}#{Kernel.const_get("Api").const_get(klass).const_get("ENDPOINT")}", Kernel.const_get("Api").const_get("#{klass}Controller".to_sym)
    end

    # If you need finer control you may want to comment out the above and rather set the endpoints manually here.
    # post ApiStatus::ENDPOINT, ApiStatusController

    not_found do
      run PageNotFoundController.new
    end

  end
end
