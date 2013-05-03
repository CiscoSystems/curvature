module Ropenstack
=begin
	* Name: Quantum
	* Description: An implementation of the Quantum V2.0 API Client in Ruby
	* Authors: Sam 'Tehsmash' Betts, John Davidge
	* Date: 01/15/2013
=end
  class Quantum < OpenstackService
    ##
    # Get a list of a tenants networks
    # 
    # :call-seq:
    #   networks(id) => A single network with the id matching the parameter
    #   networks => All networks visible to the tenant making the request
    ##
    def networks(id = nil)
      endpoint = "networks"
      unless id.nil?
        endpoint = endpoint + "/" + id
      end
      return get_request(address(endpoint), @token)
    end 

    ##
    # Get a list of subnets 
    ##
    def subnets
      return get_request(address("subnets"), @token)
    end 

    ##
    # Get a list of ports
    ##
    def ports
      return get_request(address("ports"), @token)
    end 

    ##
    # Get a list of ports specific to a device_id
    ##
    def device_ports(device_id)
      return get_request(address("ports?device_id=#{device_id}"), @token)
    end 

    ##
    # Get a list of a tenants routers
    # 
    # :call-seq:
    #   routers(id) => A single router with the id matching the parameter
    #   routers => All routers visible to the tenant making the request
    ##
    def routers(id = nil)
      endpoint = "routers"
      unless id.nil?
        endpoint = endpoint + "/" + id
      end
      return get_request(address(endpoint), @token)
    end 

    ##
    # Get a full list of floating ips for the tenant
    ##
    def floating_ips
      return get_request(address("floatingips"), @token)
    end

    def create_floating_ip(network, port = nil)
      data = {
        'floatingip' => {
          'floating_network_id' => network
        }
      }
      unless port.nil?
        data['floatingip']['port_id'] = port
      end
      return post_request(address('floatingips'), data, @token)
    end

    def delete_floating_ip(id)
      return delete_request(address("floatingips/#{id}"), @token)
    end

    def update_floating_ip(id, port)
      data = {
        'floatingip' => {
          'port_id' => port
        }
      }
      return put_request(address("floatingips/#{id}"), data, @token)
    end

    ##
    # Create a new network on Openstack given a name and tenant id.
    ## 
    def create_network(name, tenant, admin_state_up = true)
      data = {
        'network' => {
          'name' => name,
          'tenant_id' => tenant,
          'admin_state_up' => admin_state_up
        }   
      }
      return post_request(address("networks"), data, @token)
    end 

    ##
    # Create a new ipv4 subnet in a network, given a network id, and
    # a IP range in CIDR format.
    ##
    def create_subnet(network, cidr)
      data = {
        'subnet' => {
          'network_id' => network,
          'ip_version' => 4,
          'cidr' => cidr
        }   
      }
      return post_request(address("subnets"), data, @token)
    end 

    ##
    # Create a new port given network and device ids, optional 
    # parameter subnet id allows for scoping the port to a single subnet. 
    ##
    def create_port(network, subnet = nil, device = nil, device_owner = nil)
      data = {
        'port' => {
          'network_id' => network,
        }   
      }
      unless device_owner.nil?
        data['port']['device_owner'] = device_owner
      end
      unless device.nil?
        data['port']['device_id'] = device
      end
      unless subnet.nil?
        data['port']['fixed_ips'] = [{'subnet_id' => subnet}]
      end
  
      puts data

      return post_request(address("ports"), data, @token)
    end 

    ##
    # Create a new router with a given name.
    ##
    def create_router(name, admin_state_up = true)
      data = {
        'router' =>{
          'name' => name,
          'admin_state_up' => admin_state_up,
        }   
      }
      return post_request(address("routers"), data, @token)
    end 

    ##
    # Connect a router to a subnet, given router id and subnet id.
    ##
    def add_router_interface(router, subnet)
      data = { 'subnet_id' => subnet } 
      return put_request(address("routers/"+router+"/add_router_interface"), data, @token)
    end

    ##
    # Enable external connectivity through this router by connecting it to
    # an "external network"
    ##
    def add_router_gateway(router, network_id)
      data = { 'router' => {'external_gateway_info' => { 'network_id' => network_id }}}
      return put_request(address("routers/"+router), data, @token)
    end

    ##
    # Update a specific ports fixed_ips, including subnet and ip data.
    ##
    def update_port(port, fixed_ips) 
      data = { 'port' => { 'fixed_ips' => fixed_ips } }
      return put_request(address("ports/"+port), data, @token)
    end

    ##
    # Weird function for adding a port to multiple subnets if nessessary.
    ##
    def move_port_to_subnets(port_id, subnet_ids)
      id_list = Array.new()
      subnet_ids.each do |id|
        id_list << { "subnet_id" => id }
      end
      return update_port(port_id, id_list)
    end

    ##
    # Delete a port given a port id.
    ##
    def delete_port(port)
      return delete_request(address("ports/" + port), @token)
    end

    ##
    # Delete a network given a network id.
    ##
    def delete_network(network)
      return delete_request(address("networks/" + network), @token)
    end 

    ##
    # Delete a subnet given a subnet id
    ##
    def delete_subnet(subnet)
      return delete_request(address("subnets/" + subnet), @token)
    end
  
    ##
    # Delete a router given a routers id.
    ##
    def delete_router(router)
      return delete_request(address("routers/" + router), @token)
    end

    ##
    # Clear a routers external gateway information given a router id.  
    ##
    def delete_router_gateway(router)
      data = { 'router' => {'external_gateway_info' => nil}}
      return put_request(address('routers/' + router), data, @token)
    end

    ##
    # Delete a connection between a subnet and router given either port
    # or subnet ids.
    #
    # :call-seq:
    #   delete_router_interface(router_id, subnet_id, "subnet")
    #   delete_router_interface(router_id, port_id, "port")
    ##
    def delete_router_interface(router, id, type)
      data = case type
        when 'port' then { 'port_id' => id }
        when 'subnet' then { 'subnet_id' => id } 
        else raise "Invalid Interface Type"  
        end
      return put_request(address("routers/" + router + "/remove_router_interface"), data, @token)
    end

    private

    def address(endpoint)
      super("/v2.0/#{endpoint}")
    end
  end
end
