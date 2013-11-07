require 'net/http'
require 'json'
require 'uri'

module Ropenstack
=begin
	* Name: Rest
	* Description: A generic wrapper for basic rest functions with JSON data which return ruby hashes.
	* Author: Sam "Tehsmash" Betts
	* Date: 12/18/2012
=end
  class Rest
    ##
    # Build a HTTP object having been given a timeout and a URI object 
    # Returns Net::HTTP object.
    ##
    def build_http(uri, timeout)
      http = Net::HTTP.new(uri.host, uri.port)
      if(timeout > 0) 
              http.open_timeout = timeout
              http.read_timeout = timeout
      end
      return http
    end

    ##
    # All responses from openstack where any errors need to be caught are passed through
    # this function. Unless a successful response is passed it will throw a Ropenstack
    # error. 
    # If successful returns a hash of response body, unless response body is nil then it
    # returns an empty hash.
    ##
    def error_manager(uri, response)
      case response
      when Net::HTTPSuccess then
        # This covers cases where the response may not validate as JSON.
        begin
          return JSON.parse(response.body)
        rescue
          return {}
        end
      when Net::HTTPBadRequest
        raise Ropenstack::MalformedRequestError, response.body
      when Net::HTTPNotFound
        raise Ropenstack::NotFoundError, "URI: #{uri} \n" + response.body	
      when Net::HTTPUnauthorized
        raise Ropenstack::UnauthorisedError, response.body
      else
        raise Ropenstack::RopenstackError, response.body
      end
    end

    ##
    # Builds headers for requests which send JSON data, if a keystone token is supplied  
    # it adds the X-Auth-Token field with the keystone token.
    # Returns a hash which represents the http headers in a format accepted by Net::HTTP. 
    ##
    def build_headers(token)
      headers = {'Content-Type' =>'application/json'}
      unless token.nil? 
        headers['X-Auth-Token'] = token
      end
      return headers
    end	

    ##
    # The function which you call to perform a http request 
    # using the request object given in the parameters. By
    # default manage errors is true, so all responses are passed
    # through the error manager which converts the into Ropenstack errors.
    ##
    def do_request(uri, request, manage_errors = true, timeout = 10)
      begin 
        http = build_http(uri, timeout)
        if(manage_errors)
          return error_manager(uri, http.request(request))
        else
          http.request(request)
          return { "Success" => true }
        end
      rescue Timeout::Error
        raise Ropenstack::TimeoutError, "It took longer than #{timeout} to connect to #{uri.to_s}"	
      rescue Errno::ECONNREFUSED
        raise Ropenstack::TimeoutError, "It took longer than #{timeout} to connect to #{uri.to_s}"	
      end	
    end

    ##
    # Wrapper function for a get request, just provide a uri
    # and it will return you a hash with the result data.
    # For authenticated transactions a token can be provided.
    # Implemented using the do_request method.
    ##	
    def get_request(uri, token = nil, manage_errors = true)
      request = Net::HTTP::Get.new(uri.request_uri, initheader = build_headers(token))
      return do_request(uri, request, manage_errors)
    end 

    ##
    # Wrapper function for delete requests, just provide a uri
    # and it will return you a hash with the result data.
    # For authenticated transactions a token can be provided.
    # Implemented using the do_request method.
    ##
    def delete_request(uri, token = nil, manage_errors = true)
      request = Net::HTTP::Delete.new(uri.request_uri, initheader = build_headers(token))
      return do_request(uri, request, manage_errors)
    end 

    ##
    # Wrapper function for a put request, just provide a uri
    # and a hash of the data to send, then it will return you a hash 
    # with the result data.
    # For authenticated transactions a token can be provided.
    # Implemented using the do_request method
    ##
    def put_request(uri, body, token = nil, manage_errors = true)
      request = Net::HTTP::Put.new(uri.request_uri, initheader = build_headers(token))
      request.body = body.to_json
      return do_request(uri, request, manage_errors)    
    end

    ##
    # Wrapper function for a put request, just provide a uri
    # and a hash of the data to send, then it will return you a hash 
    # with the result data.
    # For authenticated transactions a token can be provided.
    ##
    def post_request(uri, body, token = nil, manage_errors = true)
      request = Net::HTTP::Post.new(uri.request_uri, initheader = build_headers(token))
      request.body = body.to_json
      return do_request(uri, request, manage_errors)    
    end 
  end
end
