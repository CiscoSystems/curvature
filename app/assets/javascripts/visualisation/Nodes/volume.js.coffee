# Volume class (not deployable)
#
class Nodes.Volume extends Nodes.Node
  # Construct a new Volume Object
  #
  # @param data [Object] Data to assign to the new Node
  #
  constructor: (data) ->
    super(data, "volume")