# Container Visualisation
# A visualisation for containers
#
class D3.LiveContainerVisualisation extends D3.Graph

  constructor: (@divclass) ->
    @containerNodes = new D3.GraphNodes(this)
    super(@divclass, 800, @containerNodes)
    
    ## Add images and containers to tools	
    @tools.listOfTools.containers.splice(0,@tools.listOfTools.containers.length)
    for container in App.donabe.containers.get()
      @tools.listOfTools.containers.push new Nodes.Container(container, "deployed")
    @tools.listOfTools.images.splice(0,@tools.listOfTools.images.length)
    for image in App.openstack.images.get()
      if (image.disk_format isnt "aki") and (image.disk_format isnt "ari")
        @tools.listOfTools.images.push image
        
    @levels = []
        
  # @property [String] ID of container being displayed, empty if new
  livecontainerid: ""
  
  displayLiveContainer: (containerid) ->
    found = false
    for l in @levels
      found = true if l is containerid
    
    @levels.push(containerid) if not found
    
    @livecontainerid = containerid
    this.clearGraph()
    
    # Draw containers
    for activeContainer in App.donabe.deployed_containers.get()
      if App.donabe.deployed_containers.inContainer(activeContainer['id'], @livecontainerid)
        this.nodes.newNode(new Nodes.Container(activeContainer, 'deployed'))
        
        ##Add Endpoint
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
      
    # Display Routers
    this.displayRouters()
      
    # Display all the Networks
    for network in App.openstack.networks.internal.get()
      if App.donabe.deployed_containers.inContainer(network['id'], @livecontainerid)
        this.nodes.newNode(network)
      
    # Display all the vms
    for vm in App.openstack.servers.get()
      if App.donabe.deployed_containers.inContainer(vm['id'], @livecontainerid)
        this.nodes.newNode(vm)

    # Display all the links
    for port in App.openstack.ports.get()
      if (App.donabe.deployed_containers.isEndpoint(port.network_id) or App.donabe.deployed_containers.isEndpoint(port.device_id) ) or ((App.donabe.deployed_containers.inContainer(port.network_id)) or ( App.donabe.deployed_containers.inContainer(port.device_id)))
        #Display links between router and network
        if port.device_owner is "network:router_interface"
          this.links.newLink App.openstack.routers.get(port.device_id), App.openstack.networks.internal.get(port.network_id), 'deployed', 230
        #Display links between network and vm
        if port.device_owner is "compute:nova" or "compute:None"
          net = App.openstack.networks.internal.get(port.network_id)
          net ?= App.openstack.networks.external.get(port.network_id)
          this.links.newLink App.openstack.servers.get(port.device_id), net, 'deployed'
        
    @force.start()
    for i in [0..6000] 
      @force.tick()
    #@force.stop()
 
  # Code for displaying exisiting container in the case of an edit
    
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
      if App.donabe.deployed_containers.inContainer(router['id'], @livecontainerid)
        if not this.alreadyInGraph(router)
          this.nodes.newNode(router, true)
          this.links.newLink App.openstack.networks.external.get(router.external_gateway_info.network_id), router, 'deployed', 100  if router.external_gateway_info?
    @force.start()
