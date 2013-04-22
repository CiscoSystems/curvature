class Openstack::SubnetsController < ApplicationController
  def index
    json_respond quantum().subnets()
  end

  def create
    json_respond quantum().create_subnet(params[:network_id], params[:cidr])
  end

  def destroy
    json_respond quantum().delete_subnet(params[:id])
  end
end
