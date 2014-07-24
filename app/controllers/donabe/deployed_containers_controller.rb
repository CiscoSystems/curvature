class Donabe::DeployedContainersController < ApplicationController
  # Get all deployed containers
  def index
    response = get_request(URI.parse("http://"+(sesh :donabe_ip)+"/"+(sesh :current_tenant)+"/deployed_containers.json"), (sesh :current_token))
    json_respond response.body
  end

  # Launch a new container 
  def create
    response = get_request(URI.parse("http://"+(sesh :donabe_ip)+"/"+(sesh :current_tenant)+"/containers/"+params[:containerID].to_s+"/deploy.json"), (sesh :current_token))
    json_respond response.body
  end

  # Undeploy a running container
  def destroy
    response = get_request(URI.parse("http://"+(sesh :donabe_ip)+"/"+(sesh :current_tenant)+"/deployed_containers/"+params[:id].to_s+"/destroy_deployed.json"), (sesh :current_token))
    json_respond response.body

  end
end
