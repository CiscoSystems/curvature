class Openstack::PortsController < ApplicationController
  def index
    data = for_each_environment do |env|
      location = URI("http://" + env.ip + "/openstack/ports")
      JSON.parse(get_request(location, (sesh env.name)).body)
    end
    puts data
    response = { "ports"=> [] }
    data.each do |env,od|
      od["ports"].each do |network|
        network["curvature"] = env
        response["ports"] << network
      end
    end
    json_respond response
  end
end
