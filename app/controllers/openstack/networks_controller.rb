# Networks Controller
class Openstack::NetworksController < ApplicationController
  def index
    json_respond for_each_environment do |env|
      get_request(env.url+"networks", get_data(cookie[env.name]))
    end
  end
end
