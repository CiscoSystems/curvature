# 
#  donabe.js.coffee
#  
#  Donabe Object containing data returned about the current status of Donabe
# 

# Test 
App.donabe =
  containers:
    _data: []
    get: -> @_data
    populate: ->
      rest.getRequest('/donabe/containers', (resp) =>
        @_data = []
        for container in resp['containers']
          @_data.push(container)
      )
    add: (data) ->
      rest.postRequest('/donabe/containers', data, (resp) =>
        App.donabe.containers.populate()
      )
    save: (data, containerid) ->
      rest.putRequest('/donabe/containers/'+containerid+'', data, (resp) =>
        App.donabe.containers.populate()
      )
      # rewrite, should create new container specification
  deployed_containers:
    _data: []
    get: -> @_data
    inContainer: (id, containerID) -> 
      present = false
      
      if containerID?
        # Go through all containers and container elements and see if this id is present
        for container in @_data when container.id == containerID
          for subContainer in container['containers']
            if subContainer['embedded_container_id'] or subContainer['id']is id
              present = true
              break
          for router in container['routers']  
            if router['openstack_id'] is id 
              present = true
              break
          for network in container['networks']
            if network['openstack_id'] is id 
              present = true
              break
          for server in container['vms']
            if server['openstack_id'] is id 
              present = true
              break
      # Go through all containers and container elements and see if this id is present
      else
        for container in @_data
          for subContainer in container['containers']
            if subContainer['embedded_container_id'] or subContainer['id']is id
              present = true
              break
          for router in container['routers']  
            if router['openstack_id'] is id 
              present = true
              break
          for network in container['networks']
            if network['openstack_id'] is id 
              present = true
              break
          for server in container['vms']
            if server['openstack_id'] is id 
              present = true
              break
      
      present # return present
    isEndpoint: (id) -> 
      isEndpoint = false
      
      # Go through all containers and container elements and see if this id is present
      for container in @_data
        for router in container['routers']  
          if router['openstack_id'] is id 
            isEndpoint = router.endpoint
            break
        for network in container['networks']
          if network['openstack_id'] is id 
            isEndpoint = network.endpoint
            break
        for server in container['vms']
          if server['openstack_id'] is id 
            isEndpoint = server.endpoint
            break          
      
      return isEndpoint # return present

    populate: ->      
      rest.getRequest('/donabe/deployed_containers', (resp) =>
        @_data = []
        for container in resp['deployed_containers']
          @_data.push(container)
      )
    add: (data) ->
      n = new Nodes.Container(data, 'undeployed')
      @_data.push(n)
      n
  endpointsOnGraph:
    _data: []
    get: -> @_data
    add: (node) -> @_data.push(node)
