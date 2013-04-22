class Openstack::RoutersController < ApplicationController
  def index
    json_respond quantum().routers()
  end

  def create
    json_respond quantum().create_router(params[:name])
  end

  def show
  end

  def destroy
    quan = quantum()
    quan.ports()["ports"].each do |port| 
      if port["device_id"] == params[:id]
        quan.delete_router_interface(params[:id], port["id"], 'port')
      end
    end
    json_respond quan.delete_router(params[:id])
  end
end
