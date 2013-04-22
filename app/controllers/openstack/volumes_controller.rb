class Openstack::VolumesController < ApplicationController
  def index
    json_respond cinder().volumes()
  end
end
