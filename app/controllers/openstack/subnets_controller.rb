class Openstack::SubnetsController < ApplicationController
  def index
    json_respond networking().subnets()
  end

  def create
    json_respond networking().create_subnet(params[:network_id], params[:cidr])
  end

  def destroy
    json_respond networking().delete_subnet(params[:id])
  end
end
