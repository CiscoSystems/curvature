class Donabe::ContainersController < ApplicationController
  # Get a all container types
  def index
    response = get_request(URI.parse("http://"+(sesh :donabe_ip)+"/"+(sesh :current_tenant)+"/containers.json"), (sesh :current_token))
    json_respond response.body
  end

  # Create a new container 
  def create
    response = post_request(URI.parse("http://"+(sesh :donabe_ip)+"/"+(sesh :current_tenant)+"/containers.json"), params[:container].to_json, (sesh :current_token))
    json_respond response.body    

  end

  # Update a container
  def update
    response = put_request(URI.parse("http://"+(sesh :donabe_ip)+"/"+(sesh :current_tenant)+"/containers/"+params[:id]+".json"), params[:container].to_json, (sesh :current_token))
    json_respond response.body
  end

  # Delete a container
  def destroy

  end
end
