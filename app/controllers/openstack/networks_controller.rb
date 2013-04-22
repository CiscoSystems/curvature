# Networks Controller
class Openstack::NetworksController < ApplicationController
  def index
    json_respond quantum().networks()
  end

  def create
    json_respond quantum().create_network(params[:name], get_data(:current_tenant))
  end

  def show
  end

  def destroy
    json_respond quantum().delete_network(params[:id])
  end
end
