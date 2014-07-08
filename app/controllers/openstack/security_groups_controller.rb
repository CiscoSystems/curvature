class Openstack::SecurityGroupsController < ApplicationController
  def index
    json_respond compute().security_groups()
  end

  def create
    json_respond compute().create_security_group(params[:name], params[:description])
  end

  def show
    json_respond compute().security_groups(params[:id])
  end

  def destroy
    json_respond compute().destroy_security_group(params[:id])
  end
end
