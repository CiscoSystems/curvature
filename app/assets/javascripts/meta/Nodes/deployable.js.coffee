# Deployable nodes are nodes that can be deployed to openstack
#
class Nodes.Deployable extends Nodes.Node
  # deploy action
  @DEPLOYED = 1
  # terminate action
  @TERMINATED = 2

  # Construct a new Deployable node
  #
  # @param data [Object] Data to assign to the new Node
  # @param svg [String] The svg that should be used to represent the new node on the graph
  # @param deployStatus [String] Is the node deployed, undeployed or marked for deletion
  #
  constructor: (data, svg, deployStatus) ->
    super(data, svg)
    @deployStatus = deployStatus

  # Fire the deploy action
  #
  deploy: ->
    @deployStatus = "deployed"
    this.fireAction(Nodes.Deployable.DATA_CHANGED)
 
  # Fire the terminate action
  #
  terminate: ->
    this.fireAction(Nodes.Deployable.TERMINATED)
