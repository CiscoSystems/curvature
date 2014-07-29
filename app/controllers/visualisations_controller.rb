class VisualisationsController < ApplicationController
  before_filter :require_login

  def show
    @containers = !(sesh :donabe_ip).nil?
    respond_to do |format|
      format.html
    end
  end

  private

  def require_login
    unless logged_in?
      flash[:error] = "Please login to access dashboard!"
      redirect_to login_url
    end
  end
end
