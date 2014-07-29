##
# Controller to manage curvatures access to the images stored on openstack
#
class Openstack::ImagesController < ApplicationController
  ##
  # GET /openstack/images
  # Returns all the images accessible to the tenant making the request
  #
  def index
    json_respond compute().images()
  end

  ##
  # POST /openstack/images
  # Create a new image using a file provided by the user making the request
  #
  def create
    json = JSON.parse(params[:json])
    isPublic = "True"
    if json["public"] != "true"
      isPublic = "False"
    end

    json_respond( 
      image().upload_image_from_file(
        json["name"], json["disk_format"],
        json["container_format"], json["minDisk"],
        json["minRam"], isPublic, params[:image]
      )
    )
  end

  ##
  # DELETE /openstack/images/:id 
  # Delete an image given an id 
  #
  def destroy
    json_respond compute().delete_image(params[:imageID])
  end
end
