class Openstack::RouterGatewaysController < ApplicationController
  def create
    json_respond quantum().add_router_gateway(params[:router_id], params[:network_id])
  end

  def destroy
    json_respond quantum().delete_router_gateway(params[:router_id])
  end
end
