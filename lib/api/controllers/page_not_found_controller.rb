module Api
  class PageNotFoundController < Goliath::API
    include ApiHelper
    
    def response(env)
      [404, {}, ['Page not found.']]
    end
    
  end
end
