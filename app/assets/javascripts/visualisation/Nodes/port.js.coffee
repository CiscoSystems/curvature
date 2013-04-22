# Port Class
# 
class Nodes.Port
  # The constructor for a new port
  #
  # @param data [Object] The data for the new port
  #
  constructor: (data) ->
    for key in Object.keys(data)
      this[key] = data[key]
