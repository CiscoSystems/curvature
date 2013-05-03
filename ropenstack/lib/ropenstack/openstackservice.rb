require 'ropenstack/rest'

module Ropenstack
=begin
	* Name: OpenstackService
	* Description:  A parent class for all the openstack service classes, with functions
			which are generic across all services.
	* Author: Sam 'Tehsmash' Betts
	* Date: 01/15/2013
=end
  class OpenstackService < Rest
    def initialize(location, token)
      @location = location
      @token = token
    end
   
    private
    
    ##
    # Take the location URI parsed in on creation and append
    # an endpoint. Returns a new URI
    ##
    def address(endpoint)
      uri = URI.parse(@location.to_s + endpoint)
      return uri
    end
  end
end
