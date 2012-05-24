require 'childprocess' 
require 'timeout' 
require 'httparty'
require "json_spec/cucumber"

# Timeout.timeout(3) do
#   loop do
#     begin
#       HTTParty.get('http://localhost:8080')
#       break
#     rescue Errno::ECONNREFUSED => try_again
#       sleep 0.1
#     end 
#   end
# end
