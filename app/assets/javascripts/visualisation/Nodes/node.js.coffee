# Base class for all openstack data objects
#
# @example How to subclass a node
#   class Network extends App.Node
#     
class Nodes.Node
  # Data changed action
  @DATA_CHANGED = 0

  # Construct a new Node Object
  #
  # @param data [Object] Data to assign to the new Node
  # @param svg [String] The svg that should be used to represent the new node on the graph
  #
  constructor: (data, svg) ->
    @svg = svg
    this.setDataFromOpenstackData(data, false)
    @actionListeners = []

  # Add an action listener to the Node
  #
  # @param aL [Object] the action listener
  #
  addActionListener: (aL) ->
    unless @actionListeners.indexOf(aL) >= 0
      @actionListeners.push(aL)

  # Remove an action listener from Node
  #
  # @param aL [Object] the action listener
  #
  removeActionListener: (aL) ->
    @actionListeners.splice(@actionListners.indexOf(aL), 1)

  # Fire an action
  #
  # @param action [Int] The action to be fired
  #
  fireAction: (action) ->
    for aL in @actionListeners
      aL.nodeActionFired(this, action)

  # Extract the data from the json passed,
  # fire nodeDataChange event
  #
  # @param data [Object] Data to assign to the new Node
  # @param throwEvent [Boolean] Whether or not to throw a nodeDataChange Event, defaults => true 
  #
  setDataFromOpenstackData: (data, throwEvent = true) ->
    for key in Object.keys(data)
      this[key] = data[key]
    if throwEvent
      this.fireAction(Nodes.Node.DATA_CHANGED)