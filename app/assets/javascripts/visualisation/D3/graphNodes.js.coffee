# The nodes objects
#
class D3.GraphNodes

  constructor: (@graph) ->
    @nodes = []
    @currentlySelectedNode = null 

  # Setup new node to be dragged onto graph
  # Will create a new instance of the node type and add it to
  # openstack data object
  #
  # @param d [Object] The data object for the node to be setup
  # @return [Object] Node object that has been setup
  #
  setupNode: (d) ->
    node = {}
    n = {}
    n.name = 'Test'
    n.svg = d.data.svg
    if d.data.type == 'image' and (!d.data.inContainerAsEndpoint?)
      if @graph instanceof D3.ContainerVisualisation
        d.data.image = {id:d.data.id}
        d.data.flavor = {id:'1'}
        # Condition data for donabe
        if d.data.image != undefined
        	d.data.image_id = d.data.image.id
        if d.data.flavor.id != undefined
          d.data.flavor = d.data.flavor.id
        if d.data.image_name == undefined
          for image in App.openstack.images.get()
            if d.data.image_id == image.id
              d.data.image_name = image.name
              break
        if d.data.endpoint == undefined
          d.data.endpoint = false
        d.data.temp_id = this.createUUID()
        delete d.data.image
        node = new Nodes.Server(d.data, 'deployed')
      else
        n.image = {id:d.data.id}
        n.flavor = {id:'1'}
        node = App.openstack.servers.add(n)
    else if d.data instanceof Nodes.Network and (!d.data.inContainerAsEndpoint?)
      if @graph instanceof D3.ContainerVisualisation
        d.data.temp_id = this.createUUID()
        if d.data.endpoint == undefined
          d.data.endpoint = false 
        node = new Nodes.Network(d.data, 'deployed')
      else
        n.cidr = d.data.cidr
        n.name = d.data.name
        node = App.openstack.networks.internal.add(n)
      ## Fire enter CIDR dialog
      $("#newNetwork").dialog().data 'node', node
      $('#newNetworkCIDR').val('10.0.0.0/24')
      $("#newNetwork").dialog 'open'
    else if d.data instanceof Nodes.Router and (!d.data.inContainerAsEndpoint?)
      if @graph instanceof D3.ContainerVisualisation
        # Condition data for donabe
        d.data.temp_id = this.createUUID()
        if d.data.endpoint == undefined
          d.data.endpoint = false
        d.data.gateway = null
        node = new Nodes.Router(d.data,'deployed')
      else
        n.gateway = null
        node = App.openstack.routers.add(n)
    else if d.data instanceof Nodes.Container
      
      
      d.data.temp_id = this.createUUID()
      if d.data.endpoint == undefined
        d.data.endpoint = false
      if @graph instanceof D3.ContainerVisualisation
        node = new Nodes.Container(d.data)
      else
        node = App.donabe.deployed_containers.add(d.data)   
      
      for x in App.donabe.containers.get()
        if x.id == d.data.id
          innerContainer = {}
          $.extend(true, innerContainer, x)
          break

      for network in innerContainer['networks']
        if network.endpoint == true
          network.inContainerAsEndpoint = d.data['temp_id']
          network.innerContainerID = network.temp_id  
          this.newNode(new Nodes.Network(network))
          if @graph instanceof D3.Visualisation
            App.donabe.endpointsOnGraph.add(network)   
      for router in innerContainer['routers']
        if router.endpoint == true
          router.inContainerAsEndpoint = d.data['temp_id']
          router.innerContainerID = router.temp_id
          this.newNode(new Nodes.Router(router))
          if @graph instanceof D3.Visualisation
            App.donabe.endpointsOnGraph.add(router)
      for vm in innerContainer['vms']
        if vm.endpoint == true
          vm.inContainerAsEndpoint = d.data['temp_id']
          vm.innerContainerID = vm.temp_id
          this.newNode(new Nodes.Server(vm))
          if @graph instanceof D3.Visualisation
            App.donabe.endpointsOnGraph.add(vm)
      

    node # return node

  # Catch node actions.
  #
  # This will listen to actions on node and update the graph according
  # to the current state of the node data
  # 
  # @param obj the object which fired the action
  # @param action [Number] The action performed, matches against a node constant
  #
  nodeActionFired: (obj, action) ->
    switch action
      when Nodes.Node.DATA_CHANGED 
        d3Nodes = d3.selectAll('g.node') # Get all of the svg nodes
        d3Paths = d3Nodes.select('path') # Specifically get the paths of each node
        d3Nodes.each (d,i) ->
          node = d.data
          # find the correct node
          if node is obj
            #determine what type of node this is
            if node instanceof Nodes.Server
              switch node.status
                when 'BUILD'
                  d3Paths[0][i].style.fill = 'orange'
                when 'ACTIVE'
                  d3Paths[0][i].style.fill = 'black'
            else if node instanceof Nodes.Router
              if node.deployStatus is 'deployed' then d3Paths[0][i].style.fill = 'black'
            else if node instanceof Nodes.Network
              if node.deployStatus is 'deployed' then d3Paths[0][i].style.fill = 'black'
            else if node instanceof Nodes.Container
              if node.deployStatus is 'deployed' then d3Paths[0][i].style.fill = 'black'
      when Nodes.Deployable.TERMINATED
        @removeNode obj

  # Add new node to the nodes array and display on graph
  #
  # @param data [Object] The data object for the new node
  # @param displayLabel [Boolean] Flag to determine whether or not to display labels. Should be true when adding nodes that are routers from other networks
  # @param x [Number] x coordinate for the new node to be placed
  # @param y [Number] y coordinate for the new node to be placed
  #
  newNode: (data, displayLabel, x, y) ->
    data = {data} # wrap in object
    if x? && y?
      data.x = x
      data.y = y
    @nodes.push(data)
    ###
    if x? and y?
      for hull in @hullset
        #console.log @insideConvexPolygon(hull.path,x,y)
        if @insideConvexPolygon(hull.path,x,y)
          #console.log data, hull.network
          @newLink(data.data, hull.network.data)
  ###
    if data.data instanceof Nodes.Node
      data.data.addActionListener(this)

    if data.data instanceof Nodes.Container
       # Link Endpoints to their container
       for node2 in @nodes
         if (node2.data.inContainerAsEndpoint?)
           for node in @nodes
             if (node.data.temp_id == node2.data.inContainerAsEndpoint)
                this.graph.links.newLink(node.data, node2.data, "deployed")

    # drawing the actual nodes
    _this = this
    node = @graph.vis.selectAll("g.node").data(@nodes)
    nodeEnter = node.enter().append("svg:g")
      .attr("class", "node")
      .style("fill", "white")
      .call(@graph.force.drag)
      .on("mousedown", (d) ->
        if _this.graph.tools.currentTool is 'link'
          _this.graph.links.newTemporaryLink(d)
          _this.graph.links.drawTemporaryLinks()
        else if _this.graph.tools.currentTool is 'remove'
          if _this.graph instanceof D3.ContainerVisualisation
            _this.nodes.removeNode(d.data)
          else
            switch d.data.deployStatus
              when 'undeployed' #just remove the node
                d.data.terminate()
              when 'deployed'
                #set to marked and color node red
                d.data.deployStatus = 'marked'
                d3.select(this).style("fill","red")
              when 'marked'
                # set to deployed and color node white
                d.data.deployStatus = 'deployed'
                d3.select(this).style("fill","white")
          if not _this.graph.tools.currentToolLocked
            _this.graph.tools.resetTools()
        else if _this.graph.tools.currentTool is 'endpoint'
          d.data.endpoint = !d.data.endpoint
          if d.data.endpoint
            d3.select(d3.select(this)[0][0].childNodes[1]).style("fill", "blue")
          else
            d3.select(d3.select(this)[0][0].childNodes[1]).style("fill", "black")
          if not _this.graph.tools.currentToolLocked
            _this.graph.tools.resetTools()
        )
      .on("mouseup", (d) ->
        if _this.graph instanceof D3.Visualisation or _this.graph instanceof D3.LiveContainerVisualisation
          # set the previously selected none back to white and assign
          d3.select(_this.currentlySelectedNode).style("fill", ->
            switch d3.select(_this.currentlySelectedNode).data()[0].data.deployStatus
              when 'marked'
                "red"
              else
                "white"
            ) unless _this.currentlySelectedNode is null

          # clear the info about previous nodes from the screen
          d3.selectAll('.nodeInfo').remove()

          if _this.graph.tools.currentTool is "none"
            # do not continue if the node clicked was the same as the previously selected node
            unless _this.currentlySelectedNode is this 
              # Remove vm Specific tools
              if _this.currentlySelectedNode isnt null and d3.select(_this.currentlySelectedNode).data()[0].data instanceof Nodes.Server
                _this.graph.tools.listOfTools.tools.pop()
                unless _this.graph.tools.currentlyShowing isnt "tools"
                  _this.graph.tools.drawTools('tools')
        
              _this.currentlySelectedNode = this
  
              # set node color to blue indicating it is the selected node
              d3.select(this).style("fill","lightblue")
      
              # Container for lines of text
              textContainer = _this.graph.nodeInfo.append("svg:text")
                .attr('class', 'nodeInfo')
      
              # create a new line of text
              noOfLines = 1
              newLine = (txt, xpos = 25) ->
                ypos = 150
                linegap = 20
                textContainer.append("tspan")
                  .attr('x',xpos)
                  .attr('y',ypos + (linegap * noOfLines))
                  .text(txt)
                noOfLines++
        
              # Function to calculate a vms ip addresses
              addresses = (list) ->
                str = ""
                # go through networks
                for name, network of list
                  str = name + " "
                  for id, ip of network
                    str += ip.addr
                    newLine(str, 50)
      
              # Function to calculate information from subnets
              subnets = (list) ->
                for id in list
                  for sub in App.openstack.subnets.get()
                    if id is sub.id
                      str = "CIDR: " + sub.cidr
                      newLine(str, 50)
                      break
      
              if d.data instanceof Nodes.Server
                newLine("VM Name : " + d.data.name) unless d.data.name is ""
                newLine("Image Name : " + App.openstack.images.get(d.data.image.id).name)
                newLine("Status : " + if d.data.hasOwnProperty("status") then d.data.status else "Undeployed")
                newLine("Created on : " + d.data.created.split('T',1)) unless !d.data.hasOwnProperty('created')
                newLine("IP Addresses : ") unless !d.data.hasOwnProperty('addresses')
                addresses(d.data.addresses) unless !d.data.hasOwnProperty('addresses')
          
                # redraw tools if the current selected tab is tools so that
                # VM specific tools will appear
                _this.graph.tools.listOfTools.tools.push({svg:'vnc', name:'VNC'})
                unless _this.graph.tools.currentlyShowing isnt 'tools'
                  _this.graph.tools.drawTools('tools')
              ###
              if d.data instanceof Nodes.Subnet
                newLine("Name : " + d.data.name) unless d.data.name is ""
                newLine("CIDR : " + d.data.cidr)
                newLine("Gateway IP : " + d.data.gateway_ip) unless !d.data.hasOwnProperty('gateway_ip')
                newLine("IP Version : " + d.data.ip_version) unless !d.data.hasOwnProperty('ip_version')
              ###
              if d.data instanceof Nodes.Network
                newLine("Name : " + d.data.name) unless d.data.name is ""
                newLine("Status : " + if d.data.hasOwnProperty("status") then d.data.status else "Undeployed")
                newLine("Subnets : ") unless !d.data.hasOwnProperty('subnets')
                subnets(d.data.subnets) unless !d.data.hasOwnProperty('subnets')
            
              if d.data instanceof Nodes.Router
                newLine("Name : " + d.data.name) unless d.data.name is ""
                newLine("Status : " + if d.data.hasOwnProperty("status") then d.data.status else "Undeployed")
          
              if d.data instanceof Nodes.ExternalNetwork
                newLine("Name : " + d.data.name) unless d.data.name is ""
                newLine("Status : " + if d.data.hasOwnProperty("status") then d.data.status else "Undeployed")
          
              if d.data instanceof Nodes.Volume
                newLine("Name : " + d.data.display_name) unless d.data.display_name is ""
                newLine("Description : " + d.data.display_description) unless d.data.display_description is ""
                newLine("Created on : " + d.data.created_at.split('T',1))
                newLine("Size : " + d.data.size + "GB")
              
              if d.data instanceof Nodes.Container
                name = ""
                for cont in App.donabe.containers.get()
                  if cont.id is d.data.container_id
                    name = cont.name
                newLine("Name: " + name) unless name is ""
      
            else
              # Remove vm Specific tools
              if _this.currentlySelectedNode isnt null and d3.select(_this.currentlySelectedNode).data()[0].data instanceof Nodes.Server
                _this.graph.tools.listOfTools.tools.pop()
                unless _this.graph.tools.currentlyShowing isnt 'tools'
                  _this.graph.tools.drawTools('tools')

              _this.currentlySelectedNode = null
        )
    
      
      # Show dialogs on double click
      .on("dblclick", (d) -> 
        console.log d
        if _this.graph instanceof D3.ContainerVisualisation
          if d.data instanceof Nodes.Server
            $("#vm").dialog().data 'node',  d.data
            $("#vmNAME").val(d.data.name)
            $("#vmFlavor").val(d.data.flavor.id)
            $("#vm").dialog('open')
          else if d.data instanceof Nodes.Router
            $("#router").dialog().data 'node',  d.data
            $("#routerNAME").val(d.data.name)
            $("#router").dialog('open')
          else if d.data instanceof Nodes.Subnet
            $("#subnet").dialog().data 'node',  d.data
            $("#subnetCIDR").val(d.data.cidr)
            $("#subnet").dialog('open')
        else
          if _this.graph.tools.currentTool is "none"
            # Only allow the display of popup for undeployed nodes
            if d.data.deployStatus is "undeployed"
              if d.data instanceof Nodes.Router
                $("#router").dialog().data 'node',  d.data
                $("#routerNAME").val(d.data.name)
                $("#router").dialog('open')
              else if d.data instanceof Nodes.Subnet
                $("#subnet").dialog().data 'node',  d.data
                $("#subnetCIDR").val(d.data.cidr)
                $("#subnet").dialog('open')
            if d.data instanceof Nodes.ExternalNetwork
              curvy.showFloatingIpDialog(d.data)
            else if d.data instanceof Nodes.Server
              curvy.showServerDialog(d.data)
            else if d.data instanceof Nodes.Container
              if _this.graph instanceof D3.LiveContainerVisualisation
                document.liveContainer.displayLiveContainer(d.data.id)
              else
                $("#liveContainerViewer").dialog('close')
                $("#liveContainerViewer").data('containerID', d.data.id)
                $("#liveContainerViewer").dialog('open')
      )
    
      .on("mouseover", (d) ->
         _this.graph.vis.selectAll("line.link").filter(
            (z, i) ->
              if (z.source is d or z.target is d )
                true
              else
                false
            ).style("stroke-width","3px")
      )
      .on("mouseout", (d) ->
         _this.graph.vis.selectAll("line.link").style("stroke-width","1px")
      )
    nodeEnter.append("svg:circle")
      .attr("r", (d) -> 
        if d.data.inContainerAsEndpoint?
          10
        else if d.data instanceof Nodes.Server
          20
        else if d.data instanceof Nodes.Router
          25
        else if d.data instanceof Nodes.Network
          30
        else if d.data instanceof Nodes.ExternalNetwork
          35
        else if d.data instanceof Nodes.Container
          30
      )
      .style("fill", (d, i) -> d3.scale.category10(i & 3))
      .style("stroke", (d, i) -> d3.rgb(d3.scale.category10(i & 3)).darker(2))
      .attr("width", "16px")
      .attr("height", "16px")
      .style("stroke-width", 4)
    nodeEnter.append("svg:path")
      .attr("class","svgpath")
      .style("fill", (d) ->
        if _this.graph instanceof D3.ContainerVisualisation
          if d.data.inContainerAsEndpoint?
            "green"
          else if d.data.endpoint
            "blue"
          else 
            "black"
        else if _this.graph instanceof D3.LiveContainerVisualisation
          if d.data.inContainerAsEndpoint == _this.graph.livecontainerid
            "blue"
          else if d.data.inContainerAsEndpoint?
            "green"
          else 
            "black"
        else
          if d.data.inContainerAsEndpoint?
            "green"
          else
            switch d.data.deployStatus
              when 'undeployed' then "blue"
              else "black"
      )
      .attr("d", (d) -> return App.d3SVGs[d.data.svg])
      .attr("transform", (d) -> 
        if d.data.inContainerAsEndpoint?
          "scale(0.5)translate(-16,-16)"
        else if d.data instanceof Nodes.Server
          "scale(1)translate(-16,-16)"
        else if d.data instanceof Nodes.Router
          "scale(1.2)translate(-16,-16)"
        else if d.data instanceof Nodes.Network
          "scale(1.5)translate(-16,-16)"
        else if d.data instanceof Nodes.ExternalNetwork
          "scale(2)translate(-16,-16)"
        else if d.data instanceof Nodes.Container
          "scale(1.5)translate(-16,-16)"
        else
          "scale(1)translate(-16,-16)"
      )
    nodeEnter.append("svg:text")
      .attr("class", "nodeLabel")
      .style("display","none")
      .style("fill","black")
      .text((d) -> 
        d.data.name
        )
      .attr("transform", (d) -> 
        if d.data.inContainerAsEndpoint?
          "translate(25,3)"
        else if d.data instanceof Nodes.Server
          "translate(25,3)"
        else if d.data instanceof Nodes.Router
          "translate(30,3)"
        else if d.data instanceof Nodes.Network
          "translate(35,3)"
        else if d.data instanceof Nodes.ExternalNetwork
          "translate(40,3)"
        else if d.data instanceof Nodes.Container
          "translate(30,3)"
        else
          "translate(25,3)")

  # Remove a specific node from the graph based on its data object
  #
  # @param data [Object] The data object for the node to be removed
  #  
  removeNode: (obj) ->
    for n in @nodes
      if n.data is obj
        node = n
        break
    if node
      @nodes.splice(@nodes.indexOf(node), 1)
      filterNode = (obj) ->
        return (d, i) ->
          return obj is d.data
      filterNetwork = (obj) ->
        return (d, i) ->
          return obj is d.network.data
      # remove the hull if a network
      if obj instanceof Nodes.Network
        @graph.vis.selectAll(".hulls").filter(filterNetwork(obj)).remove()
      @graph.vis.selectAll("g.node").filter(filterNode(obj)).remove()
      @graph.removeNodesLinks(obj)

  ##RFC4122 compliant UUID
  createUUID: ->
    s = []
    hexDigits = "0123456789abcdef"
    for i in [0..36]
      s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1)
    s[14] = "4"
    s[19] = hexDigits.substr((s[19] & 0x3 | 0x8), 1)
    s[8] = s[13] = s[18] = s[23] = "-"
    
    uuid = s.join("")
    return uuid
