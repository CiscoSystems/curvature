class EnvironmentsController < ApplicationController
  def create
    @user = User.find(params[:user_id])
    @environment = @user.environments.create(environment_params)
    redirect_to edit_user_path(params[:user_id])
  end

  def destroy
    @user = User.find(params[:user_id])
    @env = @user.environments.find(params[:id])
    @env.destroy
    redirect_to edit_user_path(params[:user_id])
  end

  private 
    def environment_params
      params.require(:environment).permit(:ip, :username, :password, :name)
    end
end
