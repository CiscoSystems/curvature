class SetupsController < ApplicationController
  before_filter :verify_config

  def verify_config
    if(APP_CONFIG.has_key?("identity"))
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def show
    #Show form and stuff.
  end

  def create
    @ip = params[:ipaddr]
    @port = params[:port]
    config = render_to_string "curvature.yml", :layout => false
    File.open("config/curvature.yml", "w") { |file|
      file.write(config)
    }
    APP_CONFIG['identity'] = {}
    APP_CONFIG['identity']['ip'] = "http://" + @ip
    APP_CONFIG['identity']['port'] = @port
    redirect_to login_url, :notice => "Curvature Keystone Config Completed!"
  end
end
