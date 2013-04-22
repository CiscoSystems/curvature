# Container Visualisation
# A visualisation for containers
#
class D3.ContainerVisualisation extends D3.Graph

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

  # @property [String] ID of container being displayed, empty if new
  containerid: ""

  # Display a container
  #
  # @param containerid [String] The id of the container
  #
  displayExistingContainer: (containerid) ->
    # Code for displaying exisiting container in the case of an edit

    @containerid = containerid

    # Get containerJSON
    console.log App.donabe.containers.get()
    
    container = null
    for i in App.donabe.containers.get()
      console.log i['id']
      console.log containerid
      if i["id"] == containerid        
        ##container = i
        container = {}
        $.extend(true, container, i)
        console.log container
        break

    # Display Networks
    for network in container['networks']
      createUUID= ->
        s = []
        hexDigits = "0123456789abcdef"
        for i in [0..36]
          s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1)
        s[14] = "4"
        s[19] = hexDigits.substr((s[19] & 0x3 | 0x8), 1)
        s[8] = s[13] = s[18] = s[23] = "-"
    
        uuid = s.join("")
        return uuid
      
      network.id = createUUID()
      this.nodes.newNode(new Nodes.Network(network))

    # Display VMs
    for vm in container['vms']
      this.nodes.newNode(new Nodes.Server(vm))

    # Display Routers
    for router in container['routers']
      this.nodes.newNode(new Nodes.Router(router))

    # Display Containers and their endpoints
    for xcontainer in container['containers']
      xcontainer.temp_id = this.nodes.createUUID()
      console.log xcontainer
      this.nodes.newNode(new Nodes.Container(xcontainer))
      # add and connect endpoints   
      innerContainer = null
      for x in App.donabe.containers.get()
        if (toString (x['id']) == toString (xcontainer['embedded_container_id']))
          innerContainer = x
          break

      for network in innerContainer['networks']
        if network.endpoint == true
          network.inContainerAsEndpoint = xcontainer.temp_id
          console.log network
          network.innerContainerID = network.temp_id
          #delete network.temp_id     
          this.nodes.newNode(new Nodes.Network(network))      
      for router in innerContainer['routers']
        if router.endpoint == true
          router.inContainerAsEndpoint = xcontainer.temp_id
          router.innerContainerID = router.temp_id
          #delete router.temp_id
          this.nodes.newNode(new Nodes.Router(router))
      for vm in innerContainer['vms']
        if vm.endpoint == true
          vm.inContainerAsEndpoint = xcontainer.temp_id
          vm.innerContainerID = vm.temp_id
          #delete vm.temp_id
          this.nodes.newNode(new Nodes.Server(vm))

    # Display Links
  
      # Link Endpoints to their container
      for node in this.nodes.nodes
        if (node.data.inContainerAsEndpoint?)
          for node2 in this.nodes.nodes
            if (node2.data.temp_id == node.data.inContainerAsEndpoint)
              this.links.newLink(node.data, node2.data, "deployed")
    
              #Link endpoint to the nodes they are connected to.
              for endpoint in xcontainer['endpoints']
                # Got this nodes endpoint
                if endpoint.endpoint_id == node.data.innerContainerID
                  for node3 in @nodes.nodes
                    if node3.data.temp_id == endpoint.connected_id
                      this.links.newLink(node.data, node3.data, "deployed")


    for node in @nodes.nodes
      if ((node['data'] instanceof Nodes.Server) or (node['data'] instanceof Nodes.Router)) and (!node['data'].inContainerAsEndpoint?)
        
        tempids = []
        console.log node.data.networks
        for network in node['data']['networks']# for each network in node
          tempids.push(network)
        console.log tempids
        console.log "____________________!!!!!!________"
        node.data.networks.splice(0, node.data.networks.length)
        
        for tid in tempids
          for node2 in @nodes.nodes #find the node with that ID
            if (node2['data']['temp_id'] == tid['temp_id']) and (!node2.data.inContainerAsEndpoint?)
              ##Is linking nodes that it shouldent
              this.links.newLink(node.data, node2.data, "deployed")
              
              
    # start the force direction
    @force.start()
    for i in [0..6000] 
      @force.tick()
    

  # Save a container
  #
  # @param containerid [String] The id of the container
  #
  saveContainer: (containerid) ->
      
    console.log "SAVING CONTAINER"

    listOfRouters = []
    listOfNetworks = []
    listOfServers = []
    listOfContainers = []

    newNodeList = []
    $.extend(true, newNodeList, @nodes.nodes)
    
    console.log newNodeList
    console.log @nodes.nodes
    
    for node in newNodeList
     if node.data.inContainerAsEndpoint?
       for container in newNodeList
         if container.data.temp_id == node.data.inContainerAsEndpoint
           endpoints = []
           for link in @links.links
             if link.source.data == node.data && !(link.target.data instanceof Nodes.Container) 
               endpoints.push {connected_id: link.target.data.temp_id, endpoint_id: node.data.innerContainerID}
             if link.target.data == node.data && !(link.source.data instanceof Nodes.Container) 
               endpoints.push {connected_id: link.source.data.temp_id, endpoint_id: node.data.innerContainerID}
           container.data.endpoints = endpoints
           break

     else if node['data'] instanceof Nodes.Router
       listOfRouters.push node['data']
     else if node['data'] instanceof Nodes.Network
       listOfNetworks.push node['data']
     else if node['data'] instanceof Nodes.Server
       listOfServers.push node['data']
     else if node['data'] instanceof Nodes.Container
       listOfContainers.push node['data']

    ##TODO replace network objects with id of the referanced network
    ##### REFILL NETWORKS
    for server in listOfServers
      networks = []
      if server.networks?
        for network in server['networks']
          if network instanceof Nodes.Network
            networks.push {temp_id: network.temp_id}
        server.networks = networks
      else 
        server.networks = []
      delete server.actionListeners

    ##### REFILL NETWORKS!!
    for router in listOfRouters
      networks = []
      if router.networks?
        for network in router['networks']
          if network instanceof Nodes.Network
            networks.push {temp_id: network.temp_id}
        router.networks = networks
      else 
        router.networks = []
      delete router.actionListeners

    for network in listOfNetworks
      delete network.actionListeners

    for container in listOfContainers
      delete container.actionListeners
      delete container.name
      if !container.embedded_container_id?
        container.embedded_container_id = container.id
        delete container.id
      delete container.routers
      delete container.networks
      delete container.vms
      delete container.containers
      delete container.deployStatus
      delete container.endpoint

    containerName = prompt("Container Name:", "-")
    console.log "Logging for logging sake"
    if !(containerName == null)
      console.log "did the conditional conditon?"

      ##build container
      container = container: {
        name: containerName
        images_defined: true
        routers: listOfRouters
        networks: listOfNetworks
        vms: listOfServers
        containers: listOfContainers
      }

      console.log containerid
      console.log container
      console.log JSON.stringify container

      if containerid?
        return App.donabe.containers.save((JSON.stringify container), containerid)
      else
        return App.donabe.containers.add(JSON.stringify container)

