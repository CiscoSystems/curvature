require 'net/http'
require 'json'
require 'uri'

##Handles login and cookie data. Keystone initially returns only an unscoped token (a token with no tenant) that can
##only be used to retrive a list of tenants. Reauthenticating as one of those tenants will give you access to the
##components of openstack that tenant has access too.

##A recent bug with OpenStack providing tokens bigger than allowed cookie size means that we are storing the token
##rails side, and accessing this using the session.

##http://docs.openstack.org/api/openstack-identity-service/2.0/content/

class LoginsController < ApplicationController
  before_filter :check_login, :only => :show

  ##Supported Browsers
  Browser = Struct.new(:browser, :version)
  SupportedBrowsers = [
    Browser.new('Safari', '6.0.2'),
    Browser.new('Firefox', '19.0.2'),
    Browser.new('Chrome', '25.0.1364.160')
  ]

  def show
    @unsupported = false
    user_agent = UserAgent.parse(request.user_agent)
    unless SupportedBrowsers.detect { |browser| user_agent >= browser }
      browser_name = user_agent.browser
      if (browser_name.casecmp("safari") == 0 || browser_name.casecmp("firefox") == 0 || browser_name.casecmp("chrome") == 0)
        flash_string = "You appear to be using an unsupported version of " + browser_name + ". Please upgrade for the best experience."
      else
        flash_string = "You appear to be using an unsupported browser."
        @unsupported = true
      end
      flash[:unsupported] = flash_string
    end

    respond_to do |format|
      format.html
    end
  end

  ##Attempt login, store cookie, 
  def create
    begin
      keystone = Ropenstack::Keystone.new(APP_CONFIG["keystone"]["ip"], APP_CONFIG["keystone"]["port"])

      keystone.authenticate(params[:username], params[:password])

      #Set user id---------------------------------------------------------------
      store(:current_user_id, keystone.user()["id"])
      store(:current_token, keystone.token())

      #Get Default Tenant--------------------------------------------------------
      tenant_data = keystone.tenant_list()
      store(:current_tenant, tenant_data["tenants"][0]["id"])
      store(:current_tenant_name, tenant_data["tenants"][0]["name"])

      #Use this to get a scoped token--------------------------------------------
      keystone.scope_token(tenant_data["tenants"][0]["name"])		
      store(:current_token, keystone.token())

      #Parse Service Catalog-----------------------------------------------------
      store_services(keystone.services(), keystone.admin())

      #Redirect to the curvature dashboard after successfully logging in
      redirect_to visualisation_url	
    rescue Ropenstack::UnauthorisedError
      login_failed()
    rescue Ropenstack::TimeoutError
      timeout()
    end
  end
  
  ##Reauthenticate and set new scoped token
  def switch
    keystone = Ropenstack::Keystone.new(APP_CONFIG["keystone"]["ip"], APP_CONFIG["keystone"]["port"], get_data(:current_token))
    keystone.scope_token(params[:tenant_name])
    store_services(keystone.services(), keystone.admin())	
    store(:current_tenant, keystone.token_metadata()["tenant"]["id"])
    store(:current_tenant_name, keystone.token_metadata()["tenant"]["name"])
    store(:current_token, keystone.token())
    redirect_to visualisation_url
  end

  ##Used to fill out tenant switching bar in interface.
  def tenants
    keystone = Ropenstack::Keystone.new(APP_CONFIG["keystone"]["ip"], APP_CONFIG["keystone"]["port"], get_data(:current_token))
    respond_to do |format|
      format.json { render :json => keystone.tenant_list() }
    end
  end

  def current
    current_name = Storage.find(cookies[:current_tenant_name]).data
    respond_to do |format|
      format.json { render :json => {"tenant" => current_name} }
    end
  end  

  def services
    servs = Storage.find(cookies[:services]).data
    respond_to do |format|
      format.json { render :json => { "services" => servs } }
    end
  end

  ##Logout/destroy tokens
  def destroy
    clear_storages()
    flash.keep
    redirect_to root_url, :notice => "You have logged out successfully!" 
  end

  private

  def store_services(services, admin)
    servs = ""
    first = true
    services.each do |service|
      if first
        servs = "#{service["name"]}"
        first = false
      else
        servs = "#{servs},#{service["name"]}"
      end
      name = service["name"] + "_ip"
      store(name.to_sym, service["endpoints"][0]["publicURL"])
      logger.info service["endpoints"][0]["publicURL"]
    end
    if admin
      servs = "#{servs},admin"
    end
    store(:services, servs)
  end

  def clear_storages()
    known_keys = ["current_token", "current_tenant", "current_tenant_name", "current_user_id", "services"]
    cookies.each do |key, value|
      if known_keys.include?(key) || key[-3..-1].eql?("_ip")
        remove_store(key.to_sym, value) 
      end
    end
  end

  def check_login
    if logged_in?
      redirect_to visualisation_url
    end
  end

  def login_failed
    flash[:error] = "Login Unsuccessful!"
    redirect_to root_url
  end

  def timeout
    flash[:error] = "Timeout connecting to Openstack"
    redirect_to root_url
  end
end
