class D3.Links
  
  constructor: (@graph) ->
    @links = []
    @tempLinks = []
        
  # Add the node passed to the tempLinks array
  # This function works out if it can create the new link
  # or it is connecting multiple nodes to a single node
  #
  # @param d [Object] The data object of the node to be linked to/from
  #
  newTemporaryLink: (d) ->
    exists = false
    sameType = true

    console.log d
    console.log @tempLinks
    if not (d.data instanceof(Nodes.Container))
      # get object type of first temporary link
      if @tempLinks.length > 0
        firstType = Nodes.Server if @tempLinks[0].source.data instanceof(Nodes.Server)
        firstType = Nodes.Network if @tempLinks[0].source.data instanceof(Nodes.Network)
        firstType = Nodes.Router if @tempLinks[0].source.data instanceof(Nodes.Router)
        firstType = Nodes.ExternalNetwork if @tempLinks[0].source.data instanceof(Nodes.ExternalNetwork)
        firstType = Nodes.Volume if @tempLinks[0].source.data instanceof(Nodes.Volume)
        #firstType = Nodes.Container if @tempLinks[0].source.data instanceof(Nodes.Container)
        sameType = d.data instanceof firstType

      for l in @tempLinks
        exists = true if l.source is d
      console.log exists
    
      if exists 
        if @tempLinks[0].source isnt d
          @tempLinks.push {source: d}
        else
          console.log "REMOVE"
          @tempLinks.splice(0,@tempLinks.length)
          @graph.vis.selectAll("line.templink").data(@tempLinks).exit().remove()
      else
        if sameType is true
          @tempLinks.push {source: d}
        else
          # Check for connection from server to router
          if (firstType is Nodes.Server and d.data instanceof(Nodes.Router)) or (firstType is Nodes.Router and d.data instanceof(Nodes.Server))
            @tempLinks.splice(0,@tempLinks.length)
            @graph.vis.selectAll("line.templink").data(@tempLinks).exit().remove()
          #Need to check it isn't drawing a link to itself!
          #Thanks past Brad I'm doing it now
          else if @tempLinks[0].source.data isnt d.data      
            # convert temporary links to perminant links
            for l in @tempLinks
              console.log l.source
              console.log d
              this.newLink(l.source.data,d.data,'undeployed')
            
            if @graph.tools.currentToolLocked
              @tempLinks.splice(0,@tempLinks.length)
              @graph.vis.selectAll("line.templink").data(@tempLinks).exit().remove()
            else
              @graph.tools.resetTools()
          else
            if @graph.tools.currentToolLocked
              @tempLinks.splice(0,@tempLinks.length)
              @graph.vis.selectAll("line.templink").data(@tempLinks).exit().remove()
            else
              @graph.tools.resetTools()
 
  # Draw the temporary links to the screen
  #
  drawTemporaryLinks: () ->
    # Temporary links between nodes used just to visualised what is being connected
    temporaryLine = @graph.vis.selectAll("line.templink").data(@tempLinks)
    if @graph.convexHulls(@graph.nodes.nodes).length > 0 
      temporaryLine.enter().insert("svg:line","path.hulls")
        .attr("class", "templink")
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", () => @graph.mouse.x)
        .attr("y2", () => @graph.mouse.y)
        .style("stroke", "blue")
    else
      temporaryLine.enter().insert("svg:line","g.node")
        .attr("class", "templink")
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", () => @graph.mouse.x)
        .attr("y2", () => @graph.mouse.y)
        .style("stroke", "blue")

    @graph.force.start()

  # Add new link to the links array and draw it
  #
  # @param source [Node] The source of the link
  # @param target [Node] The target of the link
  # @param deployStatus [String] The deploy status of the new link
  #
  newLink: (source, target, deployStatus) ->
    #Get d3 objects for source and target
    console.log source
    console.log target
    #Setting s & t to node when getting info from openstack
    for d in @graph.nodes.nodes
      s = d if d.data is source
      t = d if d.data is target

    if s? and t?
      #Check to see if there is already a link
      exists = false
      for l in @links
        exists = true if (l.source == s or l.source == t) and (l.target == t or l.target == s)
      unless exists
          
        # Code to make a server appear as if it is part of a network
        if s.data instanceof Nodes.Server and t.data instanceof Nodes.Network and !t.data.inContainerAsEndpoint?# and !(@graph instanceof D3.ContainerVisualisation)
          #console.log s.data
          if s.data.networks
            if s.data.networks.indexOf(t.data) is -1
              #console.log s.data.networks.indexOf(t.data)
              s.data.networks.push t.data 
          else
            #console.log "creating"
            s.data.networks = []
            s.data.networks.push t.data
        else if s.data instanceof Nodes.Network and t.data instanceof Nodes.Server and !s.data.inContainerAsEndpoint?# and !(@graph instanceof D3.ContainerVisualisation)
          if t.data.networks
            t.data.networks.push s.data
          else
            t.data.networks = []
            t.data.networks.push s.data
        #console.log s.data
        
        #Routers
        if s.data instanceof Nodes.Router and t.data instanceof Nodes.Network and !t.data.inContainerAsEndpoint?
          if s.data.networks
            if s.data.networks.indexOf(t.data) is -1
              #console.log s.data.networks.indexOf(t.data)
              s.data.networks.push t.data 
          else
            #console.log "creating"
            s.data.networks = []
            s.data.networks.push t.data
        else if s.data instanceof Nodes.Network and t.data instanceof Nodes.Router and !s.data.inContainerAsEndpoint?
          if t.data.networks
            t.data.networks.push s.data
          else
            t.data.networks = []
            t.data.networks.push s.data
        #console.log s.data

        # If no connection between the two exists create one
        @links.push({source: s, target:t, deployStatus:deployStatus})
        
        # drawing the links between nodes
        line = @graph.vis.selectAll("line.link").data(@links)
        line.enter().insert("svg:line", "g.node")
          .attr("class", "link")
          .attr("x1", (d) -> d.source.x)
          .attr("y1", (d) -> d.source.y)
          .attr("x2", (d) -> d.target.x)
          .attr("y2", (d) -> d.target.y)
        .style("stroke", (d) -> 
          switch d.deployStatus
            when "deployed" then "black"
            when "undeployed" then "blue"
          )

  # Remove a single link
  #
  # @param link [Object] The link object of the link to be removed
  #
  removeLink: (link) ->
    index = -1

    for l, i in @links
      if l is link
        index = i
        break

    @links.splice(index,1) if index != -1
    @graph.vis.selectAll("line.link").data(@links).exit().remove()
    
    
  linkActionFired: (obj) ->
    console.log obj
    console.log "LINK FIRED"
    d3Links = d3.selectAll('line.link') # Get all of the svg nodes
    d3Links.each (d,i) ->
      link = d
      # find the correct node
      if link is obj
        console.log "FOUND YOU"
        console.log i
        #determine what type of node this is
        if link.deployStatus is 'deployed' then d3Links[0][i].style.stroke = 'black'