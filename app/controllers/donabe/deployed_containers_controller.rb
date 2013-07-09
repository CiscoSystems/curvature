class Donabe::DeployedContainersController < ApplicationController
  # Get all deployed containers
  def index
    response = get_request(URI.parse("http://"+Storage.find(cookies[:donabe_ip]).data+"/"+Storage.find(cookies[:current_tenant]).data+"/deployed_containers.json"), Storage.find(cookies[:current_token]).data)
    json_respond response.body
  end

  # Launch a new container 
  def create
    response = get_request(URI.parse("http://"+Storage.find(cookies[:donabe_ip]).data+"/"+Storage.find(cookies[:current_tenant]).data+"/containers/"+params[:containerID].to_s+"/deploy.json"), Storage.find(cookies[:current_token]).data)
    json_respond response.body
  end

  # Undeploy a running container
  def destroy
    response = get_request(URI.parse("http://"+Storage.find(cookies[:donabe_ip]).data+"/"+Storage.find(cookies[:current_tenant]).data+"/deployed_containers/"+params[:id].to_s+"/destroy_deployed.json"), Storage.find(cookies[:current_token]).data)
    json_respond response.body

  end
end
