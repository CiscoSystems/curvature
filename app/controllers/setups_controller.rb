class SetupsController < ApplicationController
  before_filter :verify_config

  def verify_config
    if(APP_CONFIG.has_key?("keystone"))
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def show
  end

  def create
  end
end
