# Container Class
#
class Nodes.Container extends Nodes.Deployable

  constructor: (data, deployStatus) ->
    
    super(data, "container", deployStatus)
    
  deploy: (deployableLinks)->
    ##CAll super somehwre
    promise = new $.Deferred()
    
    console.log this.id
    console.log this.temp_id
    console.log this.deployStatus
    
    if this.temp_id? 
      oldTempID = this.temp_id
    else 
      oldTempID = this.id
    
    console.log "HERE!!!"
    if @deployStatus == "undeployed"
      rest.postRequest('/donabe/deployed_containers', "{\"containerID\" : \"#{@id}\"}", (resp) =>
        this.setDataFromOpenstackData(resp['container'])
        console.log "Deployed a Container!"
        super()
        
        $.when(
          App.donabe.deployed_containers.populate()
          App.openstack.networks.populate()
          App.openstack.subnets.populate()
          App.openstack.ports.populate()
          App.openstack.servers.populate()
          App.openstack.routers.populate()
        ).then(=>
          console.log App.openstack.routers.get()[0]
          endpoints = App.donabe.endpointsOnGraph.get()
          for endpoint in endpoints
            if endpoint.inContainerAsEndpoint == oldTempID
              for network in resp.container.networks
                if endpoint.innerContainerID == network.temp_id
                  openstackObj = new Nodes.Network(@getOpenStackObject(network.openstack_id, App.openstack.networks.internal.get()))
                  @addLinks(endpoint, openstackObj, window.curvy.networkVisualisation.links.links,deployableLinks)
              for router in resp.container.routers
                if endpoint.innerContainerID == router.temp_id
                  openstackObj = new Nodes.Router(@getOpenStackObject(router.openstack_id, App.openstack.routers.get()))
                  @addLinks(endpoint, openstackObj, window.curvy.networkVisualisation.links.links,deployableLinks)
              for server in resp.container.vms
                if endpoint.innerContainerID == server.temp_id
                  openstackObj = new Nodes.Server(@getOpenStackObject(server.openstack_id, App.openstack.servers.get()))
                  @addLinks(endpoint, openstackObj, window.curvy.networkVisualisation.links.links,deployableLinks)
          promise.resolve()
        )
      )
      console.log this.deployStatus
      return promise.promise()
     
  getOpenStackObject: (id, objectList) ->
    for component in objectList
      if component.id == id
        console.log "hehe"
        console.log component
        return component
    
  addLinks:(endpoint, openstackObj, list, deployableLinks) ->
    key = -1
    
    for link in list
      console.log "-----==-=-=-=-=-"
      console.log link.source.data
      console.log link.target.data
      console.log endpoint
      console.log openstackObj
      if link.source.data.temp_id == endpoint.temp_id
        console.log "SWAPPED"
        link.source.data = openstackObj ##TODO this maybe isnt WORKING CHECK IT OUT!
      else if link.target.data.temp_id == endpoint.temp_id
        console.log "SWAPPED 2"
        link.target.data = openstackObj
      
      if link.target.data instanceof Nodes.Server 
        if link.source.data instanceof Nodes.Volume 
          key = 6
        else
          key = 2
      else if link.target.data instanceof Nodes.Network 
        if link.source.data instanceof Nodes.Router 
          key = 0
        else
          key = 2
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
        deployableLinks[key].push(link)
      else if link.deployStatus == "undeployed"
        deployableLinks[key+1].push(link)
      else
        console.log("Doing nothing!")

  #terminate: ->

