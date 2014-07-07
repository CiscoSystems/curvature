class LoginsController < ApplicationController
  def show
  end

  def destroy
  end

  def create
    @user = User.find_by username: params[:username]
    if @user.password = params[:password]  
      # Sign into every environment this user has setup
      user.environments.each do |env|  
        response = post_request(env.url, {})
      end
    end
  end
end
