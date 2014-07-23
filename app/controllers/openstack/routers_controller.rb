class Openstack::RoutersController < ApplicationController
  def index
    data = for_each_environment do |env|
      location = URI("http://" + env.ip + "/openstack/routers")
      JSON.parse(get_request(location, (sesh env.name)).body)
    end
    response = { "routers"=> [] }
    data.each do |env,od|
      od["routers"].each do |network|
        network["curvature"] = env
        response["routers"] << network
      end
    end
    json_respond response
  end
end
