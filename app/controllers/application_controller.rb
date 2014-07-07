require 'net/http'
require 'json'
require 'uri'
require 'ropenstack'

##
# Application controller, parent class to all other controllers, provides all methods which are used in
# multiple controllers
#
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  ##
  # A simple helper function which provides the 'respond_to do' for a list
  # to be returned in the json format.
  #
  def json_respond(list) 
    respond_to do |format|
      format.json{ render :json => list }
    end
  end

  ##
  # A helper method to abstract doing things in every one of the user environments
  #
  def for_each_environment
    response = {}
    user = User.find(session[:user_id])
    user.environments.each do |env|  
      response[env.name] = yield env
    end
    return response
  end

  # -----------------------------------------------------------------------
  # :section: Rest Utility Functions
  # This section of the Application controller provides function wrappers for
  # the basic http requested needed to talk to a REST API.
  # -----------------------------------------------------------------------

  ##
  # Build a http request using the URI specified, sets the timeout of the 
  # operation to 10 seconds for both opening the connection and reading.
  #
  def build_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60
    return http
  end

  ##
  # Build the headers required to make a rest request, specifiying content type
  # and including the users token if it exists as the X-Auth-Token header.
  #
  def build_headers(cookie)
    headers = {'Content-Type' =>'application/json'}
    unless token.nil? 
      headers['Cookie'] = token
    end
    return headers
  end

  ##
  # Get request wrapper function
  # returns a HTTPResponse object
  #
  def get_request(uri, cookie)
    http = build_http(uri)
    request = Net::HTTP::Get.new(uri.request_uri, initheader = build_headers(cookie))
    return http.request(request)
  end

  ##
  # Delete request wrapper function
  # returns a HTTPResponse object
  #
  def delete_request(uri)
    http = build_http(uri)
    request = Net::HTTP::Delete.new(uri.request_uri, initheader = build_headers())
    return http.request(request)
  end

  ##
  # Put request wrapper function
  # returns a HTTPResponse object
  #
  def put_request(uri, body, token)
    http = build_http(uri)
    request = Net::HTTP::Put.new(uri.request_uri, initheader = build_headers(token))
    request.body = body
    return http.request(request)		
  end

  ##
  # Post request wrapper function
  # returns a HTTPResponse object
  #
  def post_request(uri, body, token)
    http = build_http(uri)
    request = Net::HTTP::Post.new(uri.request_uri, initheader = build_headers(token))
    request.body = body
    return http.request(request)		
  end

  # --------------------------------------------------------------------------------
  # :section: Cookies
  # Functions to do with the management and storage of data in the cookie.
  # --------------------------------------------------------------------------------

  ##
  # A utility function for getting the data out from the storages table using the id 
  # stored in the cookie.
  #
  def get_data(key)
    Storage.find(cookies[key]).data
  end

  ##
  # Removed a peice of data stored in the cookie object and removes it from the 
  # Storages model
  #
  def remove_store(key, value)
    begin
      @data = Storage.find(value)
      @data.destroy
      cookies.delete key
    rescue
    end
    session[key] = nil
  end
 
  ##
  # Places data into the Storages table and places the id for that peice of data into
  # the cookie with the key specified.
  #
  def store(key, data)
    store = Storage.new
    store.data = data

    if store.save 
      session[key] = store.id
      cookies[key] = store.id
    end
  end

  # :section:

  ##
  # Returns true or false only based on if the user is logged in or not
  #
  def logged_in?
    !!session[:current_token]
  end
end
