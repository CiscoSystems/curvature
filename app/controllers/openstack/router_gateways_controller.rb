class Openstack::RouterGatewaysController < ApplicationController
  def create
    json_respond networking().add_router_gateway(params[:router_id], params[:network_id])
  end

  def destroy
    json_respond networking().delete_router_gateway(params[:router_id])
  end
end
