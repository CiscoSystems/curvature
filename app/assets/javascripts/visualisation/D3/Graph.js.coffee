## D3 Graph
### Features ###
# - Tools
# - Zooming
# - Nodes
# - Linking
#
class D3.Graph
  # @property [Number] The width of the page 
  w: 0
  # @property [Number] The height of the div containing D3
  h: 0
  # @property [D3 Zoom Object] Zoom object so the scale applies to all svg elements
  zoom: {}
  # @property [D3 Drag Object] Event handler for drag events from tools
  toolsDrag: {}
  # @property [Array<Node>] Store the data to be displayed on the graph
  nodes: []
  # @property [Array<Link>] Store links between nodes displayed on the graph
  links: []
  # @property [Array<Link>] Store temporary links currently being drawn on the graph
  tempLinks: []
  # @property [Object] x & y positions of the cursor within D3 
  mouse: {}
  # @property [Object] Store the currently selected node
  currentlySelectedNode: {}
  # @property [Object] Stores the tools object
  tools: {}
  
  # Contruct a new instance of the Graph Object
  # Initialise all instance variables
  #
  # @param divClass [String] The class of the div that is to hold the D3 Graph
  #
  constructor: (@divClass, w, graphNodes) ->
    @w = w || $(window).width()
    @h = $(".#{@divClass}").height()
    @mouse = {x: null, y: null}
    @zoom = d3.behavior.zoom()
    
    if graphNodes?
      @nodes = graphNodes
    else
      @nodes = new D3.GraphNodes(this)
    @links = new D3.Links(this)
    
    # Check if a point is inside a hull
    #
    # @param hull []
    # @param x []
    # @param y []
    #
    # @return []
    #
    @insideConvexPolygon = (hull, x, y) ->
      angle = 0
      p1 = {x: 0, y:0}
      p2 = {x: 0, y:0}
  
      for i in [0..hull.length - 1]
        p1.x = hull[i][0] - x
        p1.y = hull[i][1] - y
        p2.x = hull[(i + 1) % hull.length][0] - x
        p2.y = hull[(i + 1) % hull.length][1] - y
        angle += @getAngle(p1.x,p1.y,p2.x,p2.y)
        console.log i
        console.log angle
    
      if Math.abs(angle) < Math.PI
        false
      else
        true

    # Get the angle between two coords
    #
    # @param x1 []
    # @param y1 []
    # @param x2 []
    # @param y2 []
    #
    # @return []
    #
    @getAngle = (x1,y1,x2,y2) ->
      twoPi = Math.PI * 2
  
      theta1 = Math.atan2(y1, x1)
      theta2 = Math.atan2(y2, x2)
      dTheta = theta2 - theta1

      while dTheta > Math.PI
        dTheta -= twoPi
      while dTheta < -Math.PI
        dTheta += twoPi
    
      dTheta
    
    
    # Create the hulls to group networks
    @convexHulls = (nodes, offset = 40) ->
      hulls = {}
      idNetwork = {}
      # create point sets
      k = 0

      while k < nodes.length
        n = nodes[k]
        if (n.data instanceof Nodes.Server or n.data instanceof Nodes.Network) and (!n.data.inContainerAsEndpoint)
          if n.data.networks and (!n.data.inContainerAsEndpoint?)
            for net in n.data.networks
              i = net
              l = hulls[i.id] or (hulls[i.id] = [])
              l.push [n.x - offset, n.y - offset]
              l.push [n.x - offset, n.y + offset]
              l.push [n.x + offset, n.y - offset]
              l.push [n.x + offset, n.y + offset]
          else if (n.data instanceof Nodes.Network) and (!n.data.inContainerAsEndpoint?)
            #console.log n.data
            i = n.data #if n.data instanceof Nodes.Network
            idNetwork[i.id] = n if n.data instanceof Nodes.Network
            l = hulls[i.id] or (hulls[i.id] = [])
            l.push [n.x - offset, n.y - offset]
            l.push [n.x - offset, n.y + offset]
            l.push [n.x + offset, n.y - offset]
            l.push [n.x + offset, n.y + offset]
        ++k
  
      # create convex hulls
      @hullset = []
      for i of hulls
        #console.log i
        @hullset.push({group: i, network: idNetwork[i], path: d3.geom.hull(hulls[i])})
      
      @hullset
    
    @fill = d3.scale.category20()
      
    @curve = d3.svg.line()
        .interpolate("cardinal-closed")
        .tension(.85)
    
    this.createVis()
    this.forceDirection(0.05,70, -700)
    
    @tools = new D3.Tools(this,@toolbarBackground,@outerGroup)
    @tools.drawTools('tools')

  # Setup the graph svg elements and add it to the div passed in the constructor
  #
  createVis: () ->
    @translation = {x:0,y:0} # The transaltion after a zoom

    _this = this
    # Set up the actual d3 graph outerGroup is a container for background and tools
    @outerGroup = d3.select(".#{@divClass}").append("svg:svg")
      .attr("width", '100%')
      .attr("height", '100%')
      .style("background-color", "white")
      .attr("pointer-events", "all")
      .append("svg:g")
      .call(@zoom
        .scaleExtent([0.1,1.5])
        .on "zoom", () =>
          @vis.attr("transform", "translate(" + d3.event.translate + ") scale(" + @zoom.scale() + ")")
          @translation.x = d3.event.translate[0]
          @translation.y = d3.event.translate[1]
        
        ).on "dblclick.zoom", null
    #The background for capturing mouse events
    @outerGroup.append('svg:rect')
      .attr('width', '100%')
      .attr('height', '100%')
      .attr('fill', 'white')
      .on("mousemove", -> 
        point = d3.mouse(this)
        _this.mouse.x = (point[0] - _this.translation.x) / _this.zoom.scale()
        _this.mouse.y = (point[1] - _this.translation.y) / _this.zoom.scale()
        if _this.tools.currentTool is 'link' and _this.links.tempLinks.length isnt 0 then _this.links.drawTemporaryLinks()
        )
    # Container for information about nodes
    @nodeInfo = @outerGroup.append("svg:g")
    
    #Append g for nodes to sit on
    @vis = @outerGroup.append("svg:g")
      .on("mousemove", -> 
        point = d3.mouse(this)
        _this.mouse.x = point[0]
        _this.mouse.y = point[1]
        if _this.tools.currentTool is 'link' and _this.links.tempLinks.length isnt 0 then _this.links.drawTemporaryLinks()
        )

    #Background rectangle for toolbar
    @toolbarBackground = @outerGroup.append("svg:g")
    @toolbarBackground.append('svg:rect')
      .attr('width', '445px')
      .attr('height', '93px')
      .attr('x','22')
      .attr('y','35')
      .attr("rx","5")
      .attr("ry","5")
      .attr('fill', '#7DC3F0')
      .attr("stroke-width",1)
      .attr("stroke", "#3492EF")
      
  # Setup force direction
  #
  # @param grav [Number] Set the gravitational strength to the specified value 
  # @param dist [Number] Set the link distance to the specified value 
  # @param char [Number] Set the charge strength to the specified value 
  #
  forceDirection: (grav, dist = 100, char) ->
    @force = d3.layout.force()
      .gravity(grav)
      .linkDistance(  (d) -> 
        if d.source.data instanceof Nodes.Server or d.target.data instanceof Nodes.Server 
          if d.source.data.networks then dist*d.source.data.networks.length
          else if d.target.data.networks then dist*d.target.data.networks.length
        else if d.source.data instanceof Nodes.Router or d.target.data instanceof Nodes.Router 
          if d.source.data.networks then dist*d.source.data.networks.length
          else if d.target.data.networks then dist*d.target.data.networks.length
        else 
          70
        )
      .linkStrength(0.7)
      .charge(char)
      .size([@w, @h])
      .nodes(@nodes.nodes)
      .links(@links.links)

    # When the force direction goes through and interation set the coords for links, temp links and nodes
    @force.on "tick", (e) =>
      # nodes
      @vis.selectAll("g.node")
        .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")")
        
      @vis.selectAll("path.hulls")
        .data(@convexHulls(@nodes.nodes))
          .attr("d", (d)=> @curve(d.path))
        .enter().insert("path", "g")
          .attr("class", "hulls")
          .style("fill",(d)=> @fill(d.group))
          .style("stroke",(d)=> @fill(d.group))
          .style("stroke-width", 40)
          .style("stroke-linejoin", "round")
          .style("opacity", .2)
          .on("mouseup", (d) -> 
            #if _this.tools.currentTool is 'link'
              #console.log "NEW TEMPORYLINKERE"
              #console.log d.network
              #console.log d
              #_this.links.newTemporaryLink(d.network)#PROBLEM?
              #_this.links.drawTemporaryLinks()
          )
            
      # links
      @vis.selectAll("line.link")
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)

      # temp links
      @vis.selectAll("line.templink")
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", () => @mouse.x)
        .attr("y2", () => @mouse.y)
 
  # Remove all links connected to a node
  #
  # @param node [Object] The node object to have all its links removed
  #
  removeNodesLinks: (node) ->
    linksToRemove = [] # need to have a temp list to avoid removing from @links while iterating over it
    for l in @links.links
      if l.source.data is node
        linksToRemove.push l
      else if l.target.data is node
        linksToRemove.push l
        
    for l in linksToRemove
      this.links.removeLink l
      
    @force.resume()
      
  # Clear the Graph of all nodes and links
  #
  clearGraph: () ->
    # clear the info about previous nodes from the screen
    d3.selectAll('.nodeInfo').remove()
    @currentlySelectedNode = null
    
    # clear hulls
    @vis.selectAll(".hulls").remove()
    
    #reset tools
    # TODO ADD CASE TO REMOVE VNC ON CLEAR GRAPH
    unless @tools.currentlyShowing isnt "tools"
      @tools.drawTools('tools')
    @tools.resetTools()
    
    # Remove links
    @links.links.splice(0, @links.links.length)
    @vis.selectAll("line.link").data(@links.links).exit().remove()

    # Remove nodes
    @nodes.nodes.splice(0, @nodes.nodes.length)
    @vis.selectAll("g.node").data(@nodes.nodes).exit().remove()
