# Networks Controller
class Openstack::NetworksController < ApplicationController
  def index
    data = for_each_environment do |env|
      location = URI("http://" + env.ip + "/openstack/networks")
      JSON.parse(get_request(location, (sesh env.name)).body)
    end
    response = { "networks"=> [] }
    data.each do |env,od|
      od["networks"].each do |network|
        network["curvature"] = env
        response["networks"] << network
      end
    end
    json_respond response
  end
end
