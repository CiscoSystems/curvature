class Openstack::SecurityGroupsController < ApplicationController
  def index
    json_respond nova().security_groups()
  end

  def create
    json_respond nova().create_security_group(params[:name], params[:description])
  end

  def show
    json_respond nova().security_groups(params[:id])
  end

  def destroy
    json_respond nova().destroy_security_group(params[:id])
  end
end
