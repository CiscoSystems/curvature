class Openstack::ServersController < ApplicationController
  def index
    json_respond nova().servers_detailed()
  end

  def create
    logger.info params[:nics]
    json_respond nova().create_server(params[:name], params[:image_ref], params[:flavor], params[:nics], params[:key_name], params[:security_group])
  end

  def show
    json_respond nova().servers(params[:id])
  end

  def action
    action = params[:server][:action] 
    case action 
    when "vnc","pause","unpause","reboot","suspend","resume","start","stop"
      json_respond nova().action(params[:id], action)
    when "snapshot"
      data = {'name' => params[:imageName], 'metadata' => params[:metadata]} 
      json_respond nova().action(params[:id], 'create_image', data)
    else
      raise "Invalid server action!"
    end
  end

  def quotas
    json_respond nova().quotas()
  end

  def attach_volume
    json_respond nova().attach_volume(params[:id], params[:volume_id])
  end

  def detach_volume
    json_respond nova().detach_volume(params[:id], params[:attachment_id])
  end

  def destroy
    json_respond nova().delete_server(params[:id])
  end
end
