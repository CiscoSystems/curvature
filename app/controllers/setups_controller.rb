class SetupsController < ApplicationController
  before_filter :verify_config

  def verify_config
    if(APP_CONFIG.has_key?("keystone"))
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def show
    #Show form and stuff.
  end

  def create
    if(File.exists?("config/curvature.yml"))
      @ip = params[:ipaddr]
      @port = params[:port]
      config = render_to_string "curvature.yml", :layout => false
      File.open("config/curvature.yml", "w") { |file|
        file.write(config)
      }
      APP_CONFIG['keystone'] = {}
      APP_CONFIG['keystone']['ip'] = @ip
      APP_CONFIG['keystone']['port'] = @port
    else
      #Error something something
    end
  end
end
