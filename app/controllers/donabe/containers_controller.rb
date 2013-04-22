class Donabe::ContainersController < ApplicationController
  # Get a all container types
  def index
    response = get_request(URI.parse("http://"+Storage.find(cookies[:donabe_ip]).data+"/"+Storage.find(cookies[:current_tenant]).data+"/containers.json"), Storage.find(cookies[:current_token]).data)
    json_respond response.body
  end

  # Create a new container 
  def create
    response = post_request(URI.parse("http://"+Storage.find(cookies[:donabe_ip]).data+"/"+Storage.find(cookies[:current_tenant]).data+"/containers.json"), params[:container].to_json, Storage.find(cookies[:current_token]).data)
    json_respond response.body    

  end

  # Update a container
  def update
    response = put_request(URI.parse("http://"+Storage.find(cookies[:donabe_ip]).data+"/"+Storage.find(cookies[:current_tenant]).data+"/containers/"+params[:id]+".json"), params[:container].to_json, Storage.find(cookies[:current_token]).data)
    json_respond response.body
  end

  # Delete a container
  def destroy

  end
end
