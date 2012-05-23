module Api

  class API < Grape::API

    version 'v1', :using => :path
    format :json
    default_format :json
    error_format :json
    rescue_from :all do |e|
      rack_response({ :error => "#{e.message}", :backtrace => "#{e.backtrace.join('____')}"}, 400)
    end

    desc "Retrieves the API version number."
    get "version" do
      build = "#{`git rev-list HEAD|wc -l`.strip}".to_i if File.exists?("#{ROOT_PATH}/.git")
      time = "#{`git show -s --pretty=format:"%cd"`}" if File.exists?("#{ROOT_PATH}/.git")
      {:version => self.version, :build_number => build, :build_time => time }
    end

  end

end
