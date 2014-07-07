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
    if @user.password = params[:password]  
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
      response = post_request(env.url+"/login", {})
      # Store cookie from login request response. 
      store env.name, response.response['set-cookie']
    end
  end
end
