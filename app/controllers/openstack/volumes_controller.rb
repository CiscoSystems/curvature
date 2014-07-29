class Openstack::VolumesController < ApplicationController
  def index
    json_respond blockstorage().volumes()
  end
end
