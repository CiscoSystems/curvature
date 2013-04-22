# 
#  openstack.js.coffee
#  
#  Openstack Object containing data returned about the current status of openstack components
# 


App.setNetworkInformation = (device) ->
  device.networks = []
  for port in App.openstack.ports.get()
    if port.device_id is device.id
      net = App.openstack.networks.internal.get(port.network_id)
      net ?= App.openstack.networks.external.get(port.network_id)
      device.networks.push(net) unless device.networks.indexOf(net) >= 0

App.openstack =
  tenants:
    _data: []
    get: -> @_data
    populate: ->
      @_data = []
      rest.getRequest('/login/tenants', (resp) =>
        for tenant in resp['tenants']
          @_data.push(tenant)
      )
  flavors:
    _data: []
    get: -> @_data
    populate: ->
      @_data = []
      rest.getRequest('/openstack/flavors', (resp) =>
        for flavor in resp['flavors']
          @_data.push(flavor)
      )
  images:
    _data: []
    get: (id) ->
      # if an id is passed only return that one object otherwise return all objects of this type
      if id?
        for d in @_data
          return d if d.id is id
      else
        @_data
    populate: ->
      @_data = []
      rest.getRequest('/openstack/images', (resp) =>
        for image in resp['images']
          # Work out the svg to use for an image and add it into the data
          image.svg = Nodes.Server.calculateImageSVG(image)
          image.type = 'image'
          @_data.push(image)
      )
    newImage: (name, f, disk_format, minDisk, minRam, isPublic) ->
      if isPublic is "on"
        isPublic = true
      else
        isPublic = false
  
      if f
        json = "{\"name\" : \"" + name + "\", \"disk_format\" : \"" + disk_format + "\", \"container_format\" : \"bare\", \"minDisk\" : \"" + minDisk + "\", \"minRam\" : \"" + minRam + "\",\"public\" : \"" + isPublic + "\"}"
        formData = new FormData()
        formData.append "json", json
    
        $.each f[0].files, (i, file) ->
          formData.append "image", file

        $.ajax
          url: "/openstack/images"
          type: "POST"
          cache: false
          contentType: false
          processData: false
          data: formData
          #success: (data) ->
            #callback data
      else
        alert "Failed to load image"

  quotas:
    _deta: {}
    totalInstancesUsed: -> @_data['totalInstancesUsed']
    maxTotalInstances: -> @_data['maxTotalInstances']
    totalCoresUsed: -> @_data['totalCoresUsed']
    maxTotalCores: -> @_data['maxTotalCores']
    totalRAMUsed: -> @_data['totalRAMUsed']
    maxTotalRAMSize: -> @_data['maxTotalRAMSize']
    populate: ->
      rest.getRequest('/openstack/servers/quotas', (resp) =>
        @_data = resp['limits']['absolute']
      )
  currentTenant:
    _data: ""
    get: -> @_data
    populate: ->
      rest.getRequest('/login/current', (resp) =>
        @_data = resp['tenant']
      )
    switch: (name) ->
      rest.postRequest('/login/switch', '{"tenant_name" : "'+name+'"}', (resp)->)
  subnets:
    _data: []
    get: (id) ->
      # if an id is passed only return that one object otherwise return all objects of this type
      if id?
        for d in @_data
          return d if d.id is id
      else
        @_data
    populate: ->
      @_data = []
      rest.getRequest('/openstack/subnets', (resp) =>
        for subnet in resp['subnets']
          sub = new Nodes.Subnet(subnet, 'deployed')
          sub.addActionListener(this)
          @_data.push(sub)
      )
    nodeActionFired: (node, action) ->
      if action == Nodes.Deployable.TERMINATED
        this.remove(node)
    # Called when adding a new server from the graph
    add: (data) ->
      n = new Nodes.Subnet(data, 'undeployed')
      n.addActionListener(this)
      @_data.push(n)
      n
    remove: (obj) ->
      @_data.splice(@_data.indexOf(obj),1)
  routers:
    _data: []
    get: (id) ->
      # if an id is passed only return that one object otherwise return all objects of this type
      if id?
        for d in @_data
          return d if d.id is id
      else
        @_data
    populate: ->
      @_data = []
      rest.getRequest('/openstack/routers', (resp) =>
        for router in resp['routers']
          rou = new Nodes.Router(router, 'deployed')
          rou.addActionListener(this)
          App.setNetworkInformation(rou)
          @_data.push(rou)
      )
    nodeActionFired: (node, action) ->
      switch action
        when Nodes.Deployable.TERMINATED then this.remove(node)
        when Nodes.Node.DATA_CHANGED
          App.setNetworkInformation(this)
    # Called when adding a new server from the graph
    add: (data) ->
      n = new Nodes.Router(data, 'undeployed')
      n.addActionListener(this)
      @_data.push(n)
      n
    remove: (obj) ->
      @_data.splice(@_data.indexOf(obj),1)
  networks:
    external:
      _data: []
      get: (id) ->
        # if an id is passed only return that one object otherwise return all objects of this type
        if id?
          for d in @_data
            return d if d.id is id
        else
          @_data
      add: (e) ->
        @_data.push(e)
    internal:
      _data: []
      get: (id) ->
        # if an id is passed only return that one object otherwise return all objects of this type
        if id?
          for d in @_data
            return d if d.id is id
        else
          @_data
      # Called when adding a new server from the graph
      add: (data, deployStatus = 'undeployed') ->
        n = new Nodes.Network(data, deployStatus)
        n.addActionListener(this)
        @_data.push(n)
        n
      remove: (obj) -> @_data.splice(@_data.indexOf(obj),1)
      nodeActionFired: (node, action) ->
        if action == Nodes.Deployable.TERMINATED
          this.remove(node)
    populate: ->
      @external._data = []
      @internal._data = []
      rest.getRequest('/openstack/networks', (resp) =>
        for network in resp['networks']
          if(network['router:external'])
            @external.add(new Nodes.ExternalNetwork(network))
          else
            @internal.add(network, "deployed")
      )
  ports:
    _data: []
    get: -> @_data
    add: (port) -> @_data.push(port)
    remove: (port) -> @_data.splice(@_data.indexOf(port),1)
    populate: ->
      @_data = []
      rest.getRequest('/openstack/ports', (resp) =>
        for port in resp['ports']
          @_data.push(new Nodes.Port(port))
      )
  volumes:
    _data: []
    get: (id) ->
      # if an id is passed only return that one object otherwise return all objects of this type
      if id?
        for d in @_data
          return d if d.id is id
      else
        @_data
    populate: ->
      @_data = []
      rest.getRequest('/openstack/volumes', (resp) =>
        for volume in resp['volumes']
          @_data.push(new Nodes.Volume(volume))
      )
  servers:
    _data: []
    get: (id) ->
      # if an id is passed only return that one object otherwise return all objects of this type
      if id?
        for d in @_data
          return d if d.id is id
      else
        @_data
    populate: ->
      @_data = []
      rest.getRequest('/openstack/servers', (resp) =>
        for server in resp['servers']
          ser = new Nodes.Server(server, 'deployed')
          ser.addActionListener(this)
          App.setNetworkInformation(ser)
          @_data.push(ser)
      )
    nodeActionFired: (node, action) ->
      switch action
        when Nodes.Deployable.TERMINATED then this.remove(node)
        when Nodes.Server.PORTS_CHANGED
          $.when(
            App.openstack.ports.populate()
          ).then(=>
            # Really this code needs to go somewhere else...
            App.setNetworkInformation(this)
            newPort = false
            for port in App.openstack.ports.get()
              if port.device_id is node.id
                newPort = true
                curvy.networkVisualisation.links.newLink(node, App.openstack.networks.internal.get(port.network_id), "deployed")
            for link in curvy.networkVisualisation.links.links
              if link.source.data is node || link.target.data is node
                link.deployStatus = 'deployed'
                curvy.networkVisualisation.links.linkActionFired(link)
            if newPort
              curvy.networkVisualisation.force.start()
          )
    # Called when adding a new server from the graph
    add: (data) ->
      n = new Nodes.Server(data, 'undeployed')
      n.addActionListener(this)
      @_data.push(n)
      n
    remove: (obj) ->
      @_data.splice(@_data.indexOf(obj),1)
  services:
    _data: []
    get: -> @_data
    populate: ->
      rest.getRequest('/login/services', (resp) =>
        @_data = resp["services"].split(",")
      )
  floatingIps:
    _data: []
    get: (id) ->
      if id?
        for d in @_data
          return d if d.id is id
      else
        @_data
    populate: ->
      @_data = []
      rest.getRequest('/openstack/floating_ips', (resp) =>
        @_data = resp['floatingips']
      )
    create: (ext_net) ->
      rest.postRequest('/openstack/floating_ips', "{\"network\":\"#{ext_net.id}\"}", (resp) =>
        @_data.push(resp['floatingip'])
      )
    destroy: (id) ->
      rest.deleteRequest("/openstack/floating_ips/#{id}", (resp) =>
        @_data.splice(@_data.indexOf(@get(id)), 1)
      )
    update: (id, port) ->
      rest.putRequest("/openstack/floating_ips/#{id}", "{\"port_id\":\"#{port}\"}", (resp) =>
        @_data.splice(@_data.indexOf(@get(id)), 1)
        @_data.push(resp['floatingip'])
      )
  securityGroups:
    _data: []
    get: -> @_data
    populate: ->
      rest.getRequest('/openstack/security_groups', (resp) =>
        @_data = resp['security_groups']
      )
  keypairs:
    _data: []
    get: -> @_data
    new: (name) ->
      data = "{\"name\":\"#{name}\"}"
      rest.postRequest('/openstack/keypairs', data, (resp) =>
        @_data.push(resp['keypair'])
      )
    delete: (keypair) ->
      rest.deleteRequest("/openstack/keypairs/#{keypair.name}", (resp) =>
        @_data.splice(@_data.indexOf(keypair), 1)
      )
    populate: ->
      @_data = []
      rest.getRequest('/openstack/keypairs', (resp) =>
        for k in resp['keypairs']
          @_data.push(k['keypair'])
      )
