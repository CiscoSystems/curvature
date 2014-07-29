class Openstack::RulesController < ApplicationController
  def create
    json_respond compute().create_security_group_rule(params[:protocol], params[:from], params[:to], params[:cidr], params[:security_group_id])
  end

  def destroy
    json_respond compute().destroy_security_group_rule(params[:id])
  end
end
