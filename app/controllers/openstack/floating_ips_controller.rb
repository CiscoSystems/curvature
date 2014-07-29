class Openstack::FloatingIpsController < ApplicationController
  def index
    json_respond networking().floating_ips()
  end

  def create
    json_respond networking().create_floating_ip(params[:network])
  end

  def show
  end

  def update
    port = params[:port_id]
    if port == "null"
      port = nil
    end
    json_respond networking().update_floating_ip(params[:id], port)
  end

  def destroy
    json_respond networking().delete_floating_ip(params[:id])
  end
end
