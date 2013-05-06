require 'ropenstack/rest'
require 'uri'

module Ropenstack
=begin
	* Name: Nova
	* Description: Implementation of the Nova API Client in Ruby 
	* Author: Sam 'Tehsmash' Betts
	* Date: 01/15/2013
=end
  class Nova < OpenstackService
    ##
    # Gets a list of servers from OpenStack 
    #
    # :call-seq:
    #   servers(id) => A single server with the id matching the parameter
    #   servers() => All servers visible to the tenant making the request
    ##
    def servers(id)
      endpoint = "/servers"
      unless id.nil?
        endpoint = endpoint + "/" + id
      end
      return get_request(address(endpoint), @token)
    end 

    ##
    # Gets a more detailed list of servers from openstack.
    ##
    def servers_detailed()
      return get_request(address("/servers/detail"), @token)
    end

    ##
    # Creates a server on OpenStack.
    ##
    def create_server(name, image, flavor, networks = nil, keypair = nil, security_group = nil, metadata = nil)
      data = { 
        "server" => { 
          "name" => name,
          "imageRef" => image,
          "flavorRef" => flavor,
        }   
      }
      unless networks.nil?
        data["server"]["networks"] = networks 
      end
      unless keypair.nil?
        data["server"]["key_name"] = keypair
      end
      unless security_group.nil?
        data["server"]["security_group"] = security_group 
      end
      return post_request(address("/servers"), data, @token)
    end 

    ##
    # Deletes a server from Openstack based on an id
    ##
    def delete_server(id)
      return delete_request(address("/servers/" + id), @token)
    end

    ##
    # Perform an action on a server on Openstack, by passing an id, 
    # and an action, some actions require more data.
    #
    # E.g. action(id, "reboot", "hard")
    ##
    def action(id, act, *args) 
      data = case act
        when "reboot" then {'reboot' =>{"type" => args[0]}}	
        when "vnc" then {'os-getVNCConsole' => { "type" => "novnc" }} 
        when "stop" then {'os-stop' => 'null'}
        when "start" then {'os-start' => 'null'}
        when "pause" then {'pause' => 'null'}
        when "unpause" then {'unpause' => 'null'}
        when "suspend" then {'suspend' => 'null'}
        when "resume" then {'resume' => 'null'}
        when "create_image" then {'createImage' => {'name' => args[0], 'metadata' => args[1]}} 
        else raise "Invalid Action"
        end
      return post_request(address("/servers/" + id + "/action"), data, @token)
    end

    ##
    # Attach a cinder volume to a server, by passing the server id and
    # the volume id.
    ##
    def attach_volume(id, volume) 
      data = { 'volumeAttachment' => { 'volumeId' => volume, 'device' => "/dev/vdb" } }
      return post_request(address("/servers/" + id + "/os-volume_attachments"), data, @token)
    end
    
    ##
    # Remove a cinder volume from a server, by passing the server id and
    # the attachment id.
    ##
    def detach_volume(id, attachment)
      return delete_request(address("/servers/"+id+"/os-volume_attachments/"+volume), @token)
    end

    ##
    # Retrieve a list of images from Openstack through the nova endpoint
    ##
    def images() 
      uri = URI.parse("http://" + @location.host + ":9292/v2/images")
      return get_request(uri, @token)
    end

    ##
    # Delete an image stored on Openstack through the nova endpoint
    ##
    def delete_image(id)
      uri = URI.parse("http://" + @location.host + ":" + @location.port.to_s + "/v2/images/" + id)
      return delete_request(uri, @token)
    end

    ##
    # Get a list of flavors that Servers can be
    ##
    def flavors()
      return get_request(address("/flavors/detail"), @token)	
    end

    ##
    # Get a tenants compute quotas
    ##
    def quotas()
      return get_request(address("/limits"), @token)
    end

    def security_groups(id = nil)
      endpoint = "/os-security-groups"
      unless id.nil?
        endpoint = "#{endpoint}/#{id}"
      end
      return get_request(address(endpoint), @token)
    end

    def create_security_group(name, description)
      data = { "security_group" => {"name" => name, "description" => description } }
      return post_request(address("/os-security-groups"), data, @token)
    end

    def destroy_security_group(id)
      return post_request(address("/os-security-groups/#{id}"), @token)
    end

    def create_security_group_rule(protocol, from, to, cidr, parent, group = nil)
      data = { 
        "security_group_rule" => {
          "ip_protocol" => protocol,
          "from_port" => from,
          "to_port" => to,
          "cidr" => cidr,
          "parent_group_id" => parent
        } 
      }
      unless group.nil?
        data["security_group_rule"]["group_id"] = group
      end
      return post_request(address("/os-security-group-rules"), data, @token)
    end

    def destroy_security_group_rule(id)
      return delete_request(address("/os-security-group-rules/#{id}"), @token)
    end

    def keypairs(name = nil)
      endpoint = "/os-keypairs" 
      unless name.nil?
        endpoint = "#{endpoint}/#{name}"
      end
      return get_request(address(endpoint), @token)
    end

    def create_keypair(name)
      data = { "keypair" => { "name" => name } }
      return post_request(address("/os-keypairs"), data, @token)
    end

    def delete_keypair(name)
      return delete_request(address("/os-keypairs/#{name}"), @token)
    end
  end
end
