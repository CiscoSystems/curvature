class Openstack::PortsController < ApplicationController
  def index
    json_respond networking().ports()
  end

  def create
    if params[:device_id].nil?
      json_respond networking().create_port(params[:network_id], params[:subnet_id])
    else
      json_respond networking().create_port(params[:network_id], params[:subnet_id], params[:device_id], "compute:compute")
    end
  end

  def move_port
    json = params[:subnetList].split(",")
    idList = Array.new()
    json.each do |subnetID|
            idList << { "subnet_id" => subnetID}
    end
    json_respond networking().update_port(params[:id], idList)
  end

  def destroy
    json_respond networking().delete_port(params[:id])
  end
end
