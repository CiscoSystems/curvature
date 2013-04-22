# Subnet class
#
class Nodes.Subnet extends Nodes.Deployable
  # Construct a new Subnet Object
  #
  # @param data [Object] Data to assign to the new Node
  # @param deployStatus [String] Is the node deployed, undeployed or marked for deletion
  #
  constructor: (data, deployStatus) ->
    super(data, "subnet", deployStatus)

  # Deploy a new subnet
  #
  deploy: ->
    rest.postRequest('/openstack/subnets', "{\"network_id\" : \"#{@network_id}\", \"cidr\" : \"#{@cidr}\"}", (resp) =>
      super()
      this.setDataFromOpenstackData(resp['subnet'])
    )

  # Terminate a subnet
  #
  terminate: ->
    if @deployStatus is "undeployed"
      super()
    else
      rest.deleteRequest("/openstack/subnets/#{@id}", (resp) =>
        super()
      )
