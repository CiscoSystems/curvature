require 'uri'

class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:show, :create]

  def destroy
    @user = User.find(sesh :current_user)

    ## TODO clean up environment logins
    #@user.environments.each do |env|
    #  location = URI("http://" + env.ip + "/logout")
    #  response = post_request(location, {})
    #end
  
    ## TODO: call storages clean up

    cookies.delete :sesh_id
    redirect_to login_url
  end

  def create
    @user = User.find_by username: params[:username]

    # Check user login information
    if @user.nil? or @user.password != params[:password]
        logger.debug "No user information passed"
        redirect_to login_url
    else
        # Set cookie current user id.
        sesh :current_user, @user.id
        # Sign into every environment this user has setup
        environments_signin
        redirect_to meta_url
    end
  end

  def refresh
    @user = User.find(sesh :current_user)
    environments_signin
    redirect_to meta_url
  end

  private

  def environments_signin
    @user.environments.each do |env|  
      # Fire off sign in request.
      location = URI("http://" + env.ip + "/login")
      response = post_request(location, { :username => env.username, :password => env.password }.to_json, nil)
      # Store cookie from login request response. 
      sesh env.name, response.response['set-cookie']
      # Switch to the right tenant
      location = URI("http://" + env.ip + "/login/switch")
      response = post_request(location, { :tenant_name => env.tenant }.to_json, (sesh env.name))
      sesh env.name, response.response['set-cookie']
    end
  end
end
