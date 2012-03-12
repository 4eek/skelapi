class APIClient 
  include HTTParty 
  base_uri 'http://localhost:9999'
  headers 'Content-Type' => 'application/json'
end

When /^the client requests GET (.*)$/ do |path|
  @last_response = APIClient.get(path)
end

When /^the client requests POST (.*)$/ do |path|
  @last_response = APIClient.post(path, :query => @params)
end

Then /^the reponse should be OK$/ do
  @last_response.code.should == 200
end

Then /^the reponse should be BAD REQUEST$/ do
  @last_response.code.should == 400
end

Then /^the reponse should be UNAUTHORIZED$/ do
  @last_response.code.should == 401
end

Then /^the response body should be:$/ do |string|
  @last_response.body.should == string
end

Then /^the response should be JSON:$/ do |json| 
  JSON.parse(@last_response.body).should == JSON.parse(json)
end

Given /^an invalid API key$/ do
  @api_key = "incorrect_key"
end

Given /^a valid API key$/ do
  @api_key = "i_am_awesome"
end

Given /^the following POST params$/ do |table|
  table.hashes.each do |params|
    @params = params
  end
end
