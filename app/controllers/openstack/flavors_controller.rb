class Openstack::FlavorsController < ApplicationController
  ##
  # GET /openstack/flavors
  # Returns all the flavors from openstack
  def index
    json_respond nova().flavors()
  end
end
