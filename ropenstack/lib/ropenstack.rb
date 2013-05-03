=begin
	* Name: Ropenstack
	* Description: Module used to wrap all Openstack service classes.
	* Author: Sam 'Tehsmash' Betts
	* Date: 01/15/2013
=end
module Ropenstack
  require 'ropenstack/keystone'
  require 'ropenstack/glance'
  require 'ropenstack/cinder'
  require 'ropenstack/nova'
  require 'ropenstack/quantum'
  require 'ropenstack/error'
end
