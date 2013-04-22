class VisualisationsController < ApplicationController
  before_filter :require_login

  def show
    @containers = !cookies[:donabe_ip].nil?
    respond_to do |format|
      format.html
    end
  end

  private

  def require_login
    session[:current_user_id] ||= cookies[:current_user_id]
    session[:current_token] ||= cookies[:current_token]

    #  s = Storage.find(cookies[:current_token])
    #  s.data = "FAKE"
    #  s.save
    unless logged_in?
      flash[:error] = "Please login to access dashboard!"
      redirect_to login_url
    end
  end
end
