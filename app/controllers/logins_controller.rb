require 'uri'

class LoginsController < ApplicationController
  def destroy
    @user.environments.each do |env|
      response = post_request(env.url+"/logout", {})
      remove_store(env.name, cookies[env.name])
    end

    cookies[:current_user] = nil
  end

  def create
    @user = User.find_by username: params[:username]

    # Check user login information
    if @user.password == params[:password]  
      # Set cookie current user id.
      cookies[:current_user] = @user.id
      # Sign into every environment this user has setup
      environments_signin
    end
  end

  private

  def environments_signin
    @user.environments.each do |env|  
      # Fire off sign in request.
      location = URI("http://" + env.ip + "/login")
      response = post_request(location, { :username => env.username, :password => env.password }.to_json, nil)
      # Store cookie from login request response. 
      store env.ip, response.response['set-cookie']
    end
  end
end
