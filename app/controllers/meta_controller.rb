class MetaController < ApplicationController
  def show
    @user = User.find(sesh :current_user)
    unless not (sesh :new_environments)
      sesh :new_environments, false
      redirect_to refresh_login_url
    end
  end
end
