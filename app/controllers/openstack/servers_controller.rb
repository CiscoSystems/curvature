class Openstack::ServersController < ApplicationController
  def index
    json_respond for_each_environment do |env|
      get_request(env.url, get_data(cookie[env.name]))
    end
  end

  def show
    # Get Env using params[:env]
    json_respond get_request(env.url+"servers/"+params[:id], get_data(cookie[env.name]))
  end

  def quotas
    response = for_each_environment do |env|
      location = URI("http://" + env.ip + "/openstack/servers/quotas")
      get_request(location, (sesh env.name)).body
    end
    puts response
    json_respond response
  end
end
