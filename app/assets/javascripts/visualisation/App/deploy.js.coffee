# Class Deploy manages all code for deploying a graph onto openstack.
#
class App.Deploy
  # Start a deploy 
  #
  start: ->
    # Disable deploy button so deploy can't be fired twice
    $('#deployButton').button("option", "disabled", true)
    $('#deployButton').button("option", "label", "Deploying...")

    # Initialise node deploy lists
    networksToBeDeleted = []
    networksToBeCommitted = []
    routersToBeDeleted = []
    routersToBeCommitted = []
    subnetsToBeCommitted = []
    subnetsToBeDeleted = []
    serversToBeDeleted = []
    serversToBeCommitted = []
    containersToBeDeleted = []
    containersToBeCommitted = []

    # Create Deploy and Remove lists for each deployable node type
    this.populateDeployLists(App.openstack.networks.internal.get(), networksToBeDeleted, networksToBeCommitted)
    this.populateDeployLists(App.openstack.routers.get(), routersToBeDeleted, routersToBeCommitted)
    this.populateDeployLists(App.openstack.servers.get(), serversToBeDeleted, serversToBeCommitted)
    this.populateDeployLists(App.openstack.subnets.get(), subnetsToBeDeleted, subnetsToBeCommitted)
    if App.openstack.services.get().indexOf("donabe") >= 0
      this.populateDeployLists(App.donabe.deployed_containers.get(), containersToBeDeleted, containersToBeCommitted)
      console.log containersToBeDeleted

    # Populate links deploy and delete lists
    deployableLinks = this.populateLinkLists(window.curvy.networkVisualisation.links.links)

    # Run deploy!
    $.when.apply(this, this.deployContainers(containersToBeCommitted,deployableLinks)).done(=>
      # Initialise link deploy lists 
      interfacesToBeDestroyed = deployableLinks[0]
      interfacesToBeCommitted = deployableLinks[1]
      nicsToBeDestroyed = deployableLinks[2]
      nicsToBeCommitted = deployableLinks[3]
      gatewaysToBeDestroyed = deployableLinks[4]
      gatewaysToBeCommitted = deployableLinks[5]
      attachmentsToBeDestroyed = deployableLinks[6]
      attachmentsToBeCommitted = deployableLinks[7]
      $.when.apply(this, this.terminateAttachments(attachmentsToBeDestroyed)).done(=>
        $.when.apply(this, this.terminateNics(nicsToBeDestroyed)).done(=>
          $.when.apply(this, this.terminateNodes(serversToBeDeleted)).done(=>
            $.when.apply(this, this.terminateNodes(routersToBeDeleted)).done(=>
              $.when.apply(this, this.terminateNodes(networksToBeDeleted)).done(=>
                $.when.apply(this, this.deployNodes(networksToBeCommitted)).done(=>
                  for net in networksToBeCommitted
                    sub = App.openstack.subnets.add({network_id:net.id, cidr:net.cidr})
                    subnetsToBeCommitted.push(sub)
                  $.when.apply(this, this.deployNodes(subnetsToBeCommitted)).done(=>
                    $.when.apply(this, this.deployNodes(routersToBeCommitted)).done(=>
                      $.when.apply(this, this.deployNics(nicsToBeCommitted)).done(=>
                        $.when.apply(this, this.deployNodes(serversToBeCommitted)).done(=>
                          tasks = this.terminateInterfaces(interfacesToBeDestroyed).concat(this.terminateGateways(gatewaysToBeDestroyed), this.terminateNics(nicsToBeDestroyed))
                          $.when.apply(this, tasks).done(=>
                            tasks = this.deployGateways(gatewaysToBeCommitted).concat(this.deployInterfaces(interfacesToBeCommitted), this.deployAttachments(attachmentsToBeCommitted))
                            $.when.apply(this, tasks).done(=>
                              this.deployFinished()
                            ).fail(this.deployFailed)
                          ).fail(this.deployFailed)
                        ).fail(this.deployFailed)
                      ).fail(this.deployFailed)
                    ).fail(this.deployFailed)
                  ).fail(this.deployFailed)
                ).fail(this.deployFailed)
              ).fail(this.deployFailed)
            ).fail(this.deployFailed)
          ).fail(this.deployFailed)
        ).fail(this.deployFailed)
      ).fail(this.deployFailed)
    ).fail(this.deployFailed)

  # Alert the user if the deploy has failed
  #
  deployFailed: (details) ->
    $('#deployButton').button("option", "label", "Error")
    $('#deployButton').button("option", "disabled", false)

  deployFinished: ->
    $.when(
      App.openstack.quotas.populate()
      App.openstack.ports.populate()
    ).done(=>
      curvy.displayQuotas()
    )
    $('#deployButton').button("option", "disabled", false)
    $('#deployButton').button("option", "label", "Deploy")

  # ================================================================
  # =                       Attachments                            =
  # ================================================================

  # Terminate an attachment from a server to volume
  #
  # @param server [Object] The server object that the volume is attached to
  # @param volume [Object] The volume object
  # @param link [Object] The link object that connects the volume and server
  #
  terminateAttachment: (server, volume, link) ->
    rest.postRequest("/openstack/servers/#{server.id}/detach_volume", {attachment_id:volume.attachment[0].id}, (resp) =>
      window.curvy.networkVisualisation.removeLink(link)
    )

  # Generate promises to terminate every attachment in the list passed as a param
  #
  # @param list [Array] the list of attachments that are to be terminated
  # @return [Array] the list of promises that contain the action to terminate an attachment
  #
  terminateAttachments: (list) ->
    promises = []
    for link in list
      if link.source.data instanceof Nodes.Server
        promises.push(this.terminateAttachments(link.source.data, link.target.data, link))
      else
        promises.push(this.terminateAttachments(link.target.data, link.source.data, link))
    return promises

  # Deploy an attachment
  #
  # @param server [Object] The server object that the volume is attached to
  # @param volume [Object] The volume object
  # @param link [Object] The link object that connects the volume and server
  #
  deployAttachment: (server, volume, link) ->
    rest.postRequest("/openstack/servers/#{server.id}/attach_volume", {volume_id:volume.id}, (resp) =>
      link.deployStatus = "deployed"
      curvy.networkVisualisation.links.linkActionFired(link)
      volume.deployStatus = "deployed"
    )

  # Generate promises to deploy every attachment in the list passed as a param
  #
  # @param list [Array] the list of attachments that are to be deployed
  # @return [Array] the list of promises that contain the action to deploy an attachment
  #
  deployAttachments: (list) ->
    promises = []
    for link in list
      if link.source.data instanceof Nodes.Server
        promises.push(this.deployAttachment(link.source.data, link.target.data, link))
      else
        promises.push(this.deployAttachment(link.target.data, link.source.data, link))
    return promises

  # ================================================================
  # =                           Gateways                           =
  # ================================================================

  # Terminate a gateway
  #
  # @param router [Object] The router object
  # @param link [Object] The link object between the router and the exNet
  #
  terminateGateway: (router, link) ->
    rest.deleteRequest("/openstack/routers/#{router.id}/router_gateway", (resp) =>
      router.setDataFromOpenstackData(resp['router'])
      window.curvy.networkVisualisation.removeLink(link)
    )

  # Generate promises to terminate every gateway in the list passed as a param
  #
  # @param list [Array] the list of gateway objects that should be terminated
  # @return [Array] the list of promises to terminate the gateways
  #
  terminateGateways: (list) ->
    promises = []
    for link in list
      if link.source.data instanceof Nodes.Router
        promises.push(this.terminateGateway(link.source.data, link))
      else
        promises.push(this.terminateGateway(link.target.data, link))
    return promises

  # Deploy a gateway
  #
  # @param router [Object] The router object 
  # @param network [Object] The network object
  # @param link [Object] The link object that connects the network and router
  #
  deployGateway: (router, network, link) ->
    rest.postRequest("/openstack/routers/#{router.id}/router_gateway", {network_id:network.id}, (resp) =>
      router.setDataFromOpenstackData(resp['router'])
      link.deployStatus = "deployed"
      curvy.networkVisualisation.links.linkActionFired(link)
    )

  # Generate promises to deploy the list of gateways
  #
  # @param list [Array] the list of gateways to be deployed
  # @return [Array] the list of promises to deploy gateways
  #
  deployGateways: (list) ->
    promises = []
    for link in list
      if link.source.data instanceof Nodes.Router
        promises.push(this.deployGateway(link.source.data, link.target.data, link))
      else
        promises.push(this.deployGateway(link.target.data, link.source.data, link))
    return promises

  # ==================================================================
  # =                           Interfaces                           =
  # ==================================================================

  # Terminate an interface
  #
  # @param subnet [Object] The subnet object that the router is attached to
  # @param router [Object] The router object
  # @param link [Object] The link object that connects the subnet and router
  #
  terminateInterface: (subnet, router) ->
    rest.deleteRequest("/openstack/routers/#{router.id}/router_interface/#{subnet.id}", (resp) =>
      window.curvy.networkVisualisation.removeLink(link)
    )

  # Generate promises to terminate multiple interfaces
  #
  # @param list [Array] The list of interfaces to be terminated
  # @return [Array] The list of promises to terminate interfaces
  #
  terminateInterfaces: (list) ->
    promises = []
    for link in list
      inters = []
      if link.source.data instanceof Nodes.Network
        net = link.source.data
        router = link.target.data
      else
        net = link.target.data
        router = link.source.data
      
      for subnet in App.openstack.subnets.get()
        if(subnet.network_id is net.id)
          inters.push(this.terminateInterface(subnet, router))

      pro = $.Deferred()
      $.when.apply(this, inters).then(=>
        window.curvy.networkVisualisation.removeLink(link)
        pro.resolve()
      )
      promises.push(pro)
    return promises

  # Deploy an Interface
  #
  # @param subnet [Object] The subnet object that the router is attached to
  # @param router [Object] The router object
  # @param link [Object] The link object that connects the subnet and router
  #
  deployInterface: (subnet, router) ->
    rest.postRequest("/openstack/routers/#{router.id}/router_interfaces", {subnet_id:subnet.id}, (resp) ->
      resp
      )

  # Generate promises to deploy multiple interfaces
  #
  # @param list [Array] The list of interfaces to be deployed
  # @return [Array] The list of promises to deploy interfaces
  #
  deployInterfaces: (list) ->
    linkEventFinished = (link, promise) ->
      return ->
        link.deployStatus = "deployed"
        curvy.networkVisualisation.links.linkActionFired(link)
        promise.resolve()
    promises = []
    for link in list
      inter = []
      if link.source.data instanceof Nodes.Network
        net = link.source.data
        router = link.target.data
      else
        net = link.target.data
        router = link.source.data
    
      for subnet in App.openstack.subnets.get()
        if(subnet.network_id is net.id)
          inter.push(this.deployInterface(subnet, router))

      pro = $.Deferred()
      $.when.apply(this, inter).then(linkEventFinished(link, pro))
      promises.push(pro.promise())
    return promises

  # =============================================================
  # =                           Ports                           =
  # =============================================================

  # Deploy a port
  #
  # @param subnet [Object] The subnet object
  # @param server [Object] The server object
  # @param link [Object] The link object that connects the subnet with the server
  #
  deployNic: (network, server, link) ->
    if server.deployStatus is "deployed"
      data = {network_id:network.id, device_id:server.id}
      rest.postRequest("/openstack/ports", data, (resp) =>
        link.deployStatus = "deployed"
        curvy.networkVisualisation.links.linkActionFired(link)
      )
    else
      server.newNICs.push(network.id)

  # Generate promises to deploy multiple ports
  #
  # @param list [Array] The list of ports to be deployed
  # @return [Array] The list of promises to deploy a port
  #
  deployNics: (list) ->
    promises = []
    for link in list
      if link.source.data instanceof Nodes.Network
        promises.push(this.deployNic(link.source.data, link.target.data, link))
      else
        promises.push(this.deployNic(link.target.data, link.source.data, link))
    return promises

  # Remove a port
  #
  # @param port [Object] The port object that is to be removed
  #
  terminatePort: (port) ->
    rest.deleteRequest("/openstack/ports/#{port.id}", (resp) =>
      App.openstack.ports.remove(port)
    )

  # Generate promises to remove multiple ports
  #
  # @param list [Array] The list of ports to be terminated
  # @return [Array] The list of promises to terminate a port
  #
  terminateNics: (list) ->
    promises = []
    for link in list
      if link.source.data instanceof Nodes.Network
        for port in App.openstack.ports.get()
          if port.device_id == link.target.data.id && port.fixed_ips[0]["subnet_id"] == link.source.data
            promises.push(this.terminatePort(port))
      else
        for port in App.openstack.ports.get()
          if port.device_id == link.source.data.id && port.fixed_ips[0]["subnet_id"] == link.target.data
            promises.push(this.terminatePort(port))
    return promises

  # =============================================================
  # =                           Nodes                           =
  # =============================================================

  # Generate promises for each node that needs to be terminated
  #
  # @param list [Array] The list of nodes to be terminated
  # @return [Array] The list of promises to terminate nodes
  #
  terminateNodes: (list) ->
    promises = []
    for node in list
      promises.push(node.terminate())
    return promises

  # Generate promises for each node that needs to be deployed
  #
  # @param list [Array] The list of nodes to be deployed
  # @return [Array] The list of promises to deploy nodes
  #
  deployNodes: (list) ->
    promises = []
    for node in list
      promises.push(node.deploy())
    return promises

  # Populate the deleted and committed lists with objects to be deployed
  #
  # @param list [Array] The list that is being sorted
  # @param deleted [Array] The list that will contain all nodes that need to be deleted
  # @param committed [Array] The list that will contain all nodes that need to be committed
  #
  populateDeployLists: (list, deleted, committed) ->
    for deployable in list
      console.log "ASDASDASD"
      console.log deployable
      if !deployable.inContainerAsEndpoint?
        switch deployable.deployStatus
          when "marked" then deleted.push(deployable)
          when "undeployed" then committed.push(deployable)

  # Calculate what nodes are connected and what they are connected to
  #
  # @param list [Array] List of all the link objects
  # @return [Array] An array containing all of the connections between nodes
  #
  populateLinkLists: (list) ->
    key = -1
    results = []
    for i in [0..7]
      results[i] = []
      
    for link in list when not (link.target.data.inContainerAsEndpoint? or link.source.data.inContainerAsEndpoint)
      if link.target.data instanceof Nodes.Server
        if link.source.data instanceof Nodes.Volume 
          key = 6
        else
          key = 2 ## could enter here
      else if link.target.data instanceof Nodes.Network 
        if link.source.data instanceof Nodes.Router 
          key = 0
        else
          key = 2 ##or here
      else if link.target.data instanceof Nodes.Router 
        if link.source.data instanceof Nodes.ExternalNetwork 
          key = 4
        else
          key = 0
      else if link.target.data instanceof Nodes.Volume 
        key = 6
      else if link.target.data instanceof Nodes.ExternalNetwork 
        if link.source.data instanceof Nodes.Server
          key = 2
        else
          key = 4

      if link.deployStatus == "marked"
        results[key].push(link)
      else if link.deployStatus == "undeployed"
        results[key+1].push(link)
    results

  # =============================================================
  # =                           Containers                      =
  # =============================================================

  # Generate promises for each container that needs to be deployed
  #
  # @param list [Array] The list of nodes to be deployed
  # @return [Array] The list of promises to deploy nodes
  #
  deployContainers: (list, deployableLinks) -> 
    #, endpoints, deployableLinks) ->
    promises = []
    for container in list
      ##deploy container
      promises.push(container.deploy(deployableLinks))
    return promises
    
  # Generate promises for each container that needs to be terminated
  #
  # @param list [Array] The list of nodes to be terminated
  # @return [Array] The list of promises to terminate nodes
  #
  terminateContainers: (list) ->
    promises = []
    for container in list
      promises.push(container.terminate())
    return promises
    
