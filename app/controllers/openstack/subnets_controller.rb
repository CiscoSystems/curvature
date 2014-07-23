class Openstack::SubnetsController < ApplicationController
  def index
    data = for_each_environment do |env|
      location = URI("http://" + env.ip + "/openstack/subnets")
      JSON.parse(get_request(location, (sesh env.name)).body)
    end
    response = { "subnets"=> [] }
    data.each do |env,od|
      od["subnets"].each do |network|
        network["curvature"] = env
        response["subnets"] << network
      end
    end
    json_respond response
  end
end
