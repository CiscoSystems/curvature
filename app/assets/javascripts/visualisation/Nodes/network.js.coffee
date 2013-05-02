# Network class
#
class Nodes.Network extends Nodes.Deployable
  # Construct a new Network object
  #
  # @param data [Object] Data to assign to the new Node
  #
  constructor: (data, deployStatus) ->
    data.name = "Network" if not data.name?
    super(data, "network", deployStatus)
    
  # Call the Network.terminate function on this object
  #
  terminate: ->
    Network.terminate(@id)
     
  # Create a new network
  #
  # @param name [String] The name of the new network
  #
  deploy: ->
    if @deployStatus is "undeployed"
      rest.postRequest('/openstack/networks', {name:@name}, (resp) =>
        this.setDataFromOpenstackData(resp['network'])
        super()
      )

  # Terminate a network
  #
  # @param id [String] The UUID of the network to be deleted
  #
  terminate: ->
    if @deployStatus is "undeployed"
      super()
    else
      rest.deleteRequest("/openstack/networks/#{@id}", (resp) =>
        super()
      )
