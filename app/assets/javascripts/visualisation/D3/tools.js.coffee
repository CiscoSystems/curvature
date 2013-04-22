# The toolbar objects
#
class D3.Tools
  
  constructor: (@graph) ->
    @listOfTools =
      tools: [{svg:'link', name:"Link"}, {svg:'remove', name:'Remove'}]
      toolIndex: 0
      images: []
      imageIndex: 0 # pointer to first of which 3 images are being displayed
      networking: [new Nodes.Router({},'undeployed'), new Nodes.Network({},'undeployed')]
      networkingIndex: 0
      containers: []
      containerIndex: 0
      volumes: []
      volumeIndex: 0
    
    if @graph instanceof D3.ContainerVisualisation
      @listOfTools.tools = [{svg:'link', name:"Link"}, {svg:'remove', name:'Remove'},{svg:'endpoint',name:'Endpoint'}]
    
    @currentlyShowing = 'tools'
    @currentTool = 'none'
    @currentToolLocked = false
    
    # The tools currently drawn
    @tools = []
    
    @toolsDrag = d3.behavior.drag()
      .origin(Object)
      .on("dragend", (d) => @dragEnd(d))
        
      .on("drag", (d) -> 
        d3.select(this)
          .attr("transform", (d) -> "translate(" + d3.event.x + "," + d3.event.y + ")")
        )
  
  # Draw tools to the Toolbar
  #
  # @param tools [Array<Tool>] The tools that should be drawn
  # @param type [String] The type of tools that are being drawn (e.g. Tool, Image, Networking)
  #
  drawTools: (type) ->
    @resetTools()
    
    # set currently showing
    @currentlyShowing = type
    
    switch type
      when 'tools' 
        tools = @listOfTools.tools
        index = @listOfTools.toolIndex
      when 'images' 
        tools = @listOfTools.images
        index = @listOfTools.imageIndex
      when 'networking' 
        tools = @listOfTools.networking
        index = @listOfTools.networkingIndex
      when 'containers'
        tools = @listOfTools.containers
        index = @listOfTools.containerIndex
      when 'volumes'
        tools = @listOfTools.volumes
        index = @listOfTools.volumeIndex
      else 
        tools = @listOfTools.tools 
        index = @listOfTools.toolIndex
        
    # draw the tools
    @tools.splice 0, @tools.length
    @graph.outerGroup.selectAll('.tool').remove()
    @graph.outerGroup.selectAll('.placeholders').remove()

    # Initial setup and Draw tools
    # Calculate what tools to draw
    if index >= 0 && index <= tools.length - 3
      j = 0
      for i in [index..index+2]
        x = {}
        x.fixed = true
        x.x = 117 * j + 86
        x.xo = x.x
        x.y = 100
        x.yo = 100
        x.data = tools[i]
        @tools.push(x)
        j++
    else
      for t in tools
        x = {}
        x.fixed = true
        x.x = 117 * tools.indexOf(t) + 86
        x.xo = x.x
        x.y = 100
        x.yo = 100
        x.data = t
        @tools.push(x)

    #Draw placeholders for the tools on the toolbar
    for t in @tools
      unless type is 'volumes' 
        toolsBG = @graph.toolbarBackground.append('svg:g')
          .attr('class', 'placeholders')
        toolsBG.append('svg:circle')
          .attr('r', '20')
          .attr('cx',t.xo)
          .attr('cy',t.yo)
          .attr('fill', 'white')
        toolsBG.append("svg:path")
          .style("fill","black")  
          .attr("d", App.d3SVGs[t.data.svg])
          .attr("transform", "translate("+(t.xo-16)+","+(t.yo-16)+")")
      
        if t.data.name?
          # Image Names
          toolText = toolsBG.append("svg:g")
            .attr("title",t.data.name)
            .attr("cursor","default")
          if t.data.name.length <=11 # Only have one line for text
            toolText.append("svg:text") # line one
              .attr("dx", t.xo + 25)
              .attr("dy", t.yo + 5)
              .text((d) -> t.data.name)
          else
            toolText.append("svg:text") # line one
              .attr("dx", t.xo + 25)
              .attr("dy", t.yo - 5)
              .text((d) -> t.data.name.substring(0,11))
            toolText.append("svg:text") # line two
              .attr("dx", t.xo + 25)
              .attr("dy", t.yo + 10)
              .text((d) -> 
                if (t.data.name.length > 22)
                  t.data.name.substring(11,19) + "..."
                else
                  t.data.name.substring(11,22)
                )

    # Move tools to their start posisions
    tool = @graph.outerGroup.selectAll(".tool").data(@tools)
      .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")")
    
    toolEnter = tool.enter().insert("svg:g")
      .attr("class", "tool")
      .style("fill","white") 
      
    _this = this
    switch @currentlyShowing
      when 'tools'
        toolEnter.on("click", (d) ->
          #reset so no tool is selected
          tool.style("fill", "white")
          d3.selectAll(".lockedTool").remove()
          
          #VNC
          if d.data.svg is 'vnc'
            _this.currentTool = 'vnc'
            curvy.displayVNCConsole(d3.select(_this.graph.nodes.currentlySelectedNode).data()[0].data)
            
          else if _this.currentTool isnt d.data.svg
            _this.currentTool = d.data.svg

            # change the color of the selected tool
            d3.select(this).style("fill",(d) ->
              switch d.data.svg
                when 'remove' then "#FF3333"
                when 'link' then "#add8e6"
                when 'endpoint' then "blue"
              )
          else if _this.currentTool is d.data.svg
            _this.currentTool = "none"
            _this.currentToolLocked = false
            d3.selectAll(".lockedTool").remove()
            d3.select(this).style("fill", "white")
          )
        toolEnter.on("dblclick", (d) ->
          #reset so no tool is selected
          tool.style("fill", "white")
          if _this.currentTool isnt d.data.svg and _this.currentTool isnt "vnc"
            _this.currentTool = d.data.svg
            _this.currentToolLocked = true
            # change the color of the selected tool
            d3.select(this).style("fill",(d) ->
              switch d.data.svg
                when 'remove' then "#FF3333"
                when 'link' then "#add8e6"
                when 'endpoint' then "blue"
              )
            d3.select(this).append("svg:path")
              .attr("class","lockedTool")
              .style("fill","black")
              .attr("d", App.d3SVGs["locked"])
              .attr("transform", "scale(1)")
          else if _this.currentTool is d.data.svg
            _this.currentTool = "none"
            _this.currentToolLocked = false
            d3.selectAll(".lockedTool").remove()
            d3.select(this).style("fill", "white")
        )
      else
        toolEnter.call(@toolsDrag)
        
    # Draw the draggable/clickable nodes
    toolEnter.append("svg:circle")
      .attr("r", 20)
      .attr("width", "16px")
      .attr("height", "16px")
    toolEnter.append("svg:path")
      .style("fill","black")  
      .attr("d", (d) -> return App.d3SVGs[d.data.svg])
      .attr("transform", "translate(-16,-16)")

    # Move the tools to their starting coords
    @graph.outerGroup.selectAll(".tool").data(@tools)
      .attr("transform", (d) -> "translate(" + d.xo + "," + d.yo + ")")

    # check to see if at the end of the list of images
    @drawArrows() if (@listOfTools.imageIndex < @listOfTools.images.length - 3) or (@listOfTools.containerIndex < @listOfTools.containers.length - 3) 
    @drawArrows() if (@listOfTools.imageIndex > 0) or (@listOfTools.containerIndex > 0)
    @drawArrows(tools)
  
  #reset the currently selected tools
  resetTools: () ->
    if @currentTool is "link"
      @graph.links.tempLinks.splice(0, @graph.links.tempLinks.length)
      @graph.vis.selectAll("line.templink").data(@graph.links.tempLinks).exit().remove()
    
    @currentTool = "none"
    @currentToolLocked = false
    d3.selectAll(".lockedTool").remove()
    @graph.outerGroup.selectAll('.tool').style("fill", "white")
  
  #draw arrows if there are more than three images
  drawArrows: (tools) ->
    _this = this

    toolsBG = @graph.toolbarBackground.append('svg:g')
      .attr('class', 'placeholders')
    # helper function to create rectangle around button
    draw = (obj) ->
      obj.append("svg:rect")
        .attr("width", "25")
        .attr("height", "35")
        .attr("rx","10")
        .attr("ry","10")
        .attr("transform", "translate(-5,-5)")
        .attr("stroke-width",1.5)
        .attr("stroke", "#3492EF")
      obj.append("svg:path")
        .style("fill","#3178AE")
        .attr("d", App.d3SVGs['arrow'])
      
    events = (obj,position) ->
      obj.on("mouseover", () ->  d3.select(this).style("fill","#F0F7FE"))
      obj.on("mouseout", () -> 
        d3.select(this).style("fill","#E5F2FC")#background
        d3.select(d3.select(this)[0][0].childNodes[1]).style("fill", "#3178AE") # path
        )
      obj.on("mousedown", () -> 
        d3.select(this).style("fill","#4EABE9")#background
        d3.select(d3.select(this)[0][0].childNodes[1]).style("fill", "white") # path
        )
      obj.on("mouseup", () ->
        d3.select(this).style("fill","#E5F2FC") #background
        d3.select(d3.select(this)[0][0].childNodes[1]).style("fill", "#3178AE") # path
        switch _this.currentlyShowing
          when 'tools'
            if position is "left" and _this.listOfTools.toolIndex > 0
              _this.listOfTools.toolIndex -= 1
            else if position is "right" and _this.listOfTools.toolIndex < _this.listOfTools.tools.length - 3
              _this.listOfTools.toolIndex += 1
          when 'images' 
            if position is "left" and _this.listOfTools.imageIndex > 0
              _this.listOfTools.imageIndex -= 1
            else if position is "right" and _this.listOfTools.imageIndex < _this.listOfTools.images.length - 3
              _this.listOfTools.imageIndex += 1
          when 'networking' 
            if position is "left" and _this.listOfTools.networkingIndex > 0
              _this.listOfTools.networkingIndex -= 1
            else if position is "right" and _this.listOfTools.networkingIndex < _this.listOfTools.networking.length - 3
              _this.listOfTools.networkingIndex += 1
          when 'containers'
            if position is "left" and _this.listOfTools.containerIndex > 0
              _this.listOfTools.containerIndex -= 1
            else if position is "right" and _this.listOfTools.containerIndex < _this.listOfTools.containers.length - 3
              _this.listOfTools.containerIndex += 1
          when 'volumes'
            if position is "left" and _this.listOfTools.volumeIndex > 0
              _this.listOfTools.volumeIndex -= 1
            else if position is "right" and _this.listOfTools.volumeIndex < _this.listOfTools.volumes.length - 3
              _this.listOfTools.volumeIndex += 1
          else 
            if position is "left" and _this.listOfTools.toolIndex > 0
              _this.listOfTools.toolIndex -= 1
            else if position is "right" and _this.listOfTools.toolIndex < _this.listOfTools.tools.length - 3
              _this.listOfTools.toolIndex += 1
              
        _this.drawTools(_this.currentlyShowing)
        )
        
    right = toolsBG.append("svg:g")
      .attr("fill","#E5F2FC")
      .attr("transform", "translate(435,88)")
    events(right,"right")
    draw(right,"right") # draw rectange & path
  
    left = toolsBG.append("svg:g")
      .attr("fill","#E5F2FC")
      .attr("transform", "translate(50,112) rotate(180)")
    events(left,"left")
    draw(left,"left") # draw rectange & path
    
  dragEnd: (d) ->
    if d.data instanceof Nodes.Volume
      # Remove Volume so it can't be used again
      index = -1
      for v, i in @listOfTools.volumes
        if v is d.data
          index = i
          break
      @listOfTools.volumes.splice(index,1) if index != -1
      @graph.outerGroup.selectAll(".tool").data(@listOfTools.volumes).exit().remove()
      d.data.deployStatus = 'undeployed'
      @graph.nodes.newNode(d.data, false, @graph.mouse.x, @graph.mouse.y)
    if d.data instanceof Nodes.Network
      n = {}
      n.cidr = d.data.cidr
      n.name = d.data.name
      ##RFC4122 compliant UUID
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
      n.id = createUUID()
      if @graph instanceof D3.Visualisation
        node = App.openstack.networks.internal.add(n)
      else
        node = new Nodes.Network(n, 'undeployed')
      ## Fire enter CIDR dialog
      $("#newNetwork").dialog().data 'node', node
      $("#newNetwork").dialog().data 'graph', @graph
      $('#newNetworkCIDR').val('10.0.0.0/24')
      $("#newNetwork").dialog 'open'
      
      d.x = d.xo
      d.px = d.xo
      d.y = d.yo
      d.py = d.yo

      # move the tools back to their original position
      tool = @graph.outerGroup.selectAll(".tool").data(@tools)
        .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")")
      
    else
      # create new server/subnet/router node
      @graph.nodes.newNode(@graph.nodes.setupNode(d), false, @graph.mouse.x, @graph.mouse.y)
      d.x = d.xo
      d.px = d.xo
      d.y = d.yo
      d.py = d.yo

      # move the tools back to their original position
      tool = @graph.outerGroup.selectAll(".tool").data(@tools)
        .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")")

    # start the force direction
    @graph.force.start()
    
