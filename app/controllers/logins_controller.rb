require 'uri'

class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:show, :create]

  def destroy
    @user.environments.each do |env|
      response = post_request(env.url+"/logout", {})
    end
  
    ## TODO: call storages clean up

    cookies[:sesh_id] = nil
  end

  def create
    @user = User.find_by username: params[:username]

    # Check user login information
    if @user.password == params[:password]  
      # Set cookie current user id.
      sesh :current_user, @user.id
      # Sign into every environment this user has setup
      environments_signin
      redirect_to meta_url
    end
  end

  private

  def environments_signin
    @user.environments.each do |env|  
      # Fire off sign in request.
      location = URI("http://" + env.ip + "/login")
      response = post_request(location, { :username => env.username, :password => env.password }.to_json, nil)
      # Store cookie from login request response. 
      sesh env.name, response.response['set-cookie']
    end
  end
end
