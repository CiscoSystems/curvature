## Network Visualisation Graph
# Contains code specific to drawing a network visualisation
#
class D3.Visualisation extends D3.Graph
  # @property [Array] Array of the networks that currently have their routers being displayed 
  networksOnDisplay: []
  # @property [String] The network id of the network currently being displayed
  networkid: ""

  # Function to determine whether or not a node is already in the graph
  #
  # @param data [Object] The data object of the node to be checked
  # @return [Boolean] Return whether or not the node is in the graph
  #
  alreadyInGraph: (data) ->
    for node in @nodes
      if node.data is data
        return true
    return false

  # Display all the routers for a given network
  #
  # @param networkid [String] The network id of a Network to have its routers displayed
  #
  displayRouters: () ->
    #Add routers
    for router in App.openstack.routers.get()
      if not App.donabe.deployed_containers.inContainer(router['id'])
        if not this.alreadyInGraph(router)
          this.nodes.newNode(router, true)
          this.links.newLink App.openstack.networks.external.get(router.external_gateway_info.network_id), router, 'deployed', 100  if router.external_gateway_info?
    @force.start()

  # Remove routers from a specific network
  #
  # @param networkid [String] The network id of a Network to have its routers removed
  #
  removeRouters: (networkid) ->
    #Add routers
    for router in App.openstack.routers.get()
      portExists = false
      inOtherNetwork = false
      for port in App.openstack.ports.get()
        if port.device_id is router.id and port.network_id isnt networkid
          portExists = true
          inOtherNetwork = true
        else if port.device_id is router.id and port.network_id is networkid
          portExists = true
      if portExists && not inOtherNetwork && router.deployStatus == "deployed"
        this.removeNodesLinks(router)
        this.removeNode(router)

## BRAD LINKING CODE
  hideLinks: ->
    @vis.selectAll("line.link").filter(
      (d, i) ->
        if (d.source.data instanceof Nodes.Server and d.target.data instanceof Nodes.Network) or (d.target.data instanceof Nodes.Server and d.source.data instanceof Nodes.Network)
          true
        else
          false
      ).style("display","none")     
  showLinks: ->
    @vis.selectAll("line.link").style("display","block")
## BRAD LINKING CODE
    
  # Display all Networks
  #
  displayAllNetworks: () ->
    this.clearGraph()
    
    if App.openstack.services.get().indexOf("donabe") >= 0
     # Draw containers
     
     activeContainers = [];
     $.extend(true, activeContainers, App.donabe.deployed_containers.get());
     
     for activeContainer in activeContainers
       if not App.donabe.deployed_containers.inContainer(activeContainer['id'])
         this.nodes.newNode(new Nodes.Container(activeContainer, 'deployed'))
 
         for originNetwork in activeContainer['networks']
           if originNetwork.endpoint == true
             ##Swap for real openstack object
             network= {}
             $.extend(true, network, originNetwork)
             
             temp_id = network.temp_id
             network = App.openstack.networks.internal.get(network.openstack_id)
             network.inContainerAsEndpoint = activeContainer.id
             network.innerContainerID = temp_id
             this.nodes.newNode(network) 
         for originRouter in activeContainer['routers']
           if originRouter.endpoint == true
             ##Swap for real openstack object
             router= {}
             $.extend(true, router, originRouter)
             
             temp_id = router.temp_id
             router = App.openstack.routers.get(router.openstack_id)
             router.inContainerAsEndpoint = activeContainer.id
             router.innerContainerID = temp_id
             this.nodes.newNode(router)
         for originVm in activeContainer['vms']
           if originVm.endpoint == true
             ##Swap for real openstack object
             vm= {}
             $.extend(true, vm, originVm)
             
             temp_id = vm.temp_id
             vm = App.openstack.servers.get(vm.openstack_id)
             vm.inContainerAsEndpoint = activeContainer.id
             vm.innerContainerID = temp_id
             this.nodes.newNode(vm)
         
         # Link Endpoints to their container
         for node in this.nodes.nodes
           if (node.data.inContainerAsEndpoint?)
             for node2 in this.nodes.nodes
               if (node2.data.id == node.data.inContainerAsEndpoint)
                 this.links.newLink(node.data, node2.data, "deployed")
    
    # Display all the External Networks
    for exnet in App.openstack.networks.external.get()
      this.nodes.newNode(exnet)
      
    # Display Routers
    this.displayRouters()
      
    # Display all the Networks
    for network in App.openstack.networks.internal.get()
      if not App.donabe.deployed_containers.inContainer(network['id'])
        this.nodes.newNode(network)
      
    # Display all the vms
    for vm in App.openstack.servers.get()
      if not App.donabe.deployed_containers.inContainer(vm['id'])
        this.nodes.newNode(vm)

    # Display all the links
    for port in App.openstack.ports.get()
      if (App.donabe.deployed_containers.isEndpoint(port.network_id) or App.donabe.deployed_containers.isEndpoint(port.device_id) ) or ((not App.donabe.deployed_containers.inContainer(port.network_id)) and (not App.donabe.deployed_containers.inContainer(port.device_id)))
        #Display links between router and network
        if port.device_owner is "network:router_interface"
          this.links.newLink App.openstack.routers.get(port.device_id), App.openstack.networks.internal.get(port.network_id), 'deployed', 230
        #Display links between network and vm
        if port.device_owner is "compute:nova" or "compute:None"
          net = App.openstack.networks.internal.get(port.network_id)
          net ?= App.openstack.networks.external.get(port.network_id)
          this.links.newLink App.openstack.servers.get(port.device_id), net, 'deployed'
    
    #connect endpoint routers to exnet    
    for router in App.openstack.routers.get()
      if router.inContainerAsEndpoint?
        this.links.newLink App.openstack.networks.external.get(router.external_gateway_info.network_id), router, 'deployed', 100  if router.external_gateway_info?
        
    @force.start()
    for i in [0..3000] 
      @force.tick()
    #@force.stop()
    
