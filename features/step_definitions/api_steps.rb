When /^the ([A-Za-z0-9\-\_]+) header is( temporarily)? set to (.+)$/ do |header_name,next_request_flag,header_value|
  target_headers = send(next_request_flag ? :headers_for_next_request : :headers_for_all_requests)
  target_headers[header_name] = interpolate_content header_value
end

When /(\w+) authenticates by sending a POST request to \/api\/authentication with Basic password (.*)/ do |user_name,password|

  store_preaction_state
  apply_headers_for_current_request!

  user = User.where(name: user_name).first!
  header 'Authorization', %/Basic #{Base64.strict_encode64("#{user.name}:#{password}")}/

  @response = post '/api/authentication'
  @response_body = MultiJson.load @response.body
end

When /(\w+) sends a GET request to (.*)/ do |user_name,url|

  store_preaction_state
  apply_headers_for_current_request!

  user = find_api_user user_name
  header 'Authorization', "Bearer #{user.generate_auth_token}" if user

  @request_body = nil
  @response = get interpolate_content(url)
  @response_body = MultiJson.load @response.body
end

When /(\w+) sends a POST request with the following (XML|JSON) to (.*):/ do |user_name,content_type,url,doc|

  store_preaction_state
  apply_headers_for_current_request!
  content_type = content_type.downcase.to_sym

  user = find_api_user user_name
  header 'Content-Type', "application/#{content_type}"
  header 'Authorization', "Bearer #{user.generate_auth_token}" if user

  @request_body = send "cucumber_doc_string_to_#{content_type}".to_sym, doc
  serialized_body = content_type == :json ? MultiJson.dump(@request_body) : Ox.dump(@request_body)

  @response = post interpolate_content(url), serialized_body
  @response_body = MultiJson.load @response.body
end

When /(\w+) sends a PATCH request with the following JSON to (.*):/ do |user_name,url,doc|

  store_preaction_state
  apply_headers_for_current_request!

  user = find_api_user user_name
  header 'Content-Type', 'application/json'
  header 'Authorization', "Bearer #{user.generate_auth_token}" if user

  body = cucumber_doc_string_to_json doc

  @request_body = body
  @response = patch interpolate_content(url), MultiJson.dump(@request_body)
  @response_body = MultiJson.load @response.body
end

When /(\w+) sends a DELETE request to (.*)/ do |user_name,url|

  store_preaction_state
  apply_headers_for_current_request!

  user = find_api_user user_name
  header 'Authorization', "Bearer #{user.generate_auth_token}" if user

  @request_body = nil
  @response = delete interpolate_content(url)
  @response_body = MultiJson.load @response.body unless @response.body.nil? || @response.body.empty?
end

Then /the response code should be (\d+)/ do |code|
  expect_http_status_code code.to_i
end

Then /the response body should be the following JSON:/ do |properties|
  raise "No response body found" unless @response_body
  expect_json @response_body, MultiJson.load(properties)
end

Then /the response should be HTTP (\d+) with the following JSON:/ do |code,properties|
  expect_http_status_code code.to_i
  raise "No response body found" unless @response_body
  expect_json @response_body, MultiJson.load(properties)
end

Then /the response should be HTTP (\d+) with the following errors:/ do |code,properties|

  expect_http_status_code code.to_i

  expected_errors = []

  properties.hashes.each do |h|
    expected_error = {}

    %i(path location locationType message reason).each do |attr|
      expected_error[attr] = h[attr.to_s].to_s.strip if h.key? attr.to_s
    end

    expected_errors << expected_error
  end

  expect(@response_body).to have_api_errors(expected_errors)
end
