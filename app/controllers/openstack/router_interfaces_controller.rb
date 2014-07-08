class Openstack::RouterInterfacesController < ApplicationController
  def create
    json_respond networking().add_router_interface(params[:router_id], params[:subnet_id])
  end

  def destroy
    json_respond networking().delete_router_interface(params[:router_id], params[:id], 'subnet')
  end
end
