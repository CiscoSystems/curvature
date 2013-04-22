# External network class
#
class Nodes.ExternalNetwork extends Nodes.Node
  # Construct a new External Network object
  #
  # @param data [Object] Data to assign to the new Node
  #
  constructor: (data) ->
    super(data, "external")