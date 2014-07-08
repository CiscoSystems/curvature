class Openstack::KeypairsController < ApplicationController
  def index
    json_respond compute().keypairs()
  end

  def create
    keypair = compute().create_keypair(params[:name])
    store(params[:name].to_sym, keypair['keypair']['private_key'])
    json_respond keypair 
  end

  def show
    json_respond compute().keypairs(params[:id])
  end

  def destroy
    json_respond compute().delete_keypair(params[:id])
  end

  def download
    send_data get_data(params[:id].to_sym), :filename => "#{params[:id]}.pem"
  end
end
