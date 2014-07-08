class Openstack::FlavorsController < ApplicationController
  ##
  # GET /openstack/flavors
  # Returns all the flavors from openstack
  def index
    json_respond compute().flavors()
  end
end
