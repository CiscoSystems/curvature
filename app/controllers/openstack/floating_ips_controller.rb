class Openstack::FloatingIpsController < ApplicationController
  def index
    json_respond quantum().floating_ips()
  end

  def create
    json_respond quantum().create_floating_ip(params[:network])
  end

  def show
  end

  def update
    port = params[:port_id]
    if port == "null"
      port = nil
    end
    json_respond quantum().update_floating_ip(params[:id], port)
  end

  def destroy
    json_respond quantum().delete_floating_ip(params[:id])
  end
end
