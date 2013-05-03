module Ropenstack
  ##
  # * Name: Cinder
  # * Description: Implementation of the Cinder API Client in Ruby.
  # * Author: Sam 'Tehsmash' Betts
  # * Date: 01/15/2013
  ##
  class Cinder < OpenstackService
    ##
    # Gets the volumes from cinder, and provides them in a ruby hash 
    # with all information about them.
    ## 
    def volumes(id = nil)
      endpoint = "/volumes"
      endpoint = "#{endpoint}/#{id}" unless id.nil?
      return get_request(address(endpoint), @token)
    end

    ##
    # Gets the detailed list of volumes from cinder.
    ## 
    def volumes_detailed()
      return get_request(address("/volumes/detail"), @token)
    end

    ##
    # Gets the list of volume types from cinder.
    ##
    def types(id = nil)
      endpoint = "/types"
      endpoint = "#{endpoint}/#{id}" unless id.nil?
      return get_request(address(endpoint), @token)
    end

    ##
    # Create a new volume given size, volume_type and a name
    # Optional parameters include: 
    #   * :description -> string
    #   * :metadata -> array 
    #   * :zone -> string
    ##
    def create_volume(display_name, size, volume_type, options = {})
      data = {
        "volume" => {
          "display_name" => display_name,
          "size" => size,
          "volume_type" => volume_type
        }
      } 

      data["volume"]["display_description"] = opts[:description] unless opts[:description].nil?
      data["volume"]["metadata"] = opts[:metadata] unless opts[:metadata].nil?
      data["volume"]["availability_zone"] = opts[:zone] unless opts[:zone].nil?

      return post_request(address("/volumes"), data, @token)
    end

    ##
    # Delete a volume given an ID.
    ##
    def delete(id)
      return delete_request(address("/volumes/#{id}"), @token)
    end
  end
end
