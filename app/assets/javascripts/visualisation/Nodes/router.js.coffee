# Router class
#
class Nodes.Router extends Nodes.Deployable
  # Construct a new router object
  #
  # @param data [Object] Data to assign to the new Node
  # @param deployStatus [String] Is the node deployed, undeployed or marked for deletion
  #
  constructor: (data, deployStatus) ->
    data.name = "Router" if not data.name?
    if !data.networks?
      data.networks = []
    super(data, "router", deployStatus)
  
  # Deploy a new router to openstack
  #
  deploy: ->
    rest.postRequest('/openstack/routers', {name:@name, gateway:@gateway}, (resp) =>
      super()
      this.setDataFromOpenstackData(resp['router'])
    )

  # Terminate a router
  #
  terminate: ->
    if @deployStatus is "undeployed"
      super()
    else
      rest.deleteRequest("/openstack/routers/#{@id}", (resp) =>
        super()
      )
