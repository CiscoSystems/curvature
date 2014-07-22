# Server (VM) class
#
class Nodes.Server extends Nodes.Deployable
  # Action ports changed
  @PORTS_CHANGED = 3
  # @property [Boolean] Are there any ports defined
  noPortsDefined = true

  # Construct a new Server object
  #
  # @param data [Object] Data to assign to the new Node
  # @param deployStatus [String] Is the node deployed, undeployed or marked for deletion
  #
  constructor: (data, deployStatus) ->
    if data.image != undefined
      imgSvg = Nodes.Server.calculateImageSVG(App.openstack.images.get(data.image.id))
    else if data.image_name != undefined
      imgSvg = Nodes.Server.calculateImageSVG(data.image_name)
    else
      imgSvg = "undefined"

    if !data.networks?
      data.networks = []
    super(data, imgSvg, deployStatus)
    @newNICs = []
    @noPortsDefined = true


  # Work out the type of svg to assign to an image for more images to have different
  # icons add a return statement with a pattern match
  #
  # @param image [Object] The image object to calculate an svg for
  #
  @calculateImageSVG: (image) ->
    if image?
      if image.name != undefined
        name = image.name.toLowerCase()
      else
        name = image.toLowerCase()

      return "linux" if name.search(/cirros/) is 0 or name.search(/linux/) is 0
      return "ubuntu" if name.search(/ubuntu/) is 0
      return "windows" if name.search(/windows/) is 0
      return "tinycore" if name.search(/tinycore/) or name.search(/tiny core/) is 0

    "undefined"

  # Build the JSON to send to openstack to deploy a server
  #
  # @return [String] The JSON
  #
  createData: ->
    data = {name:@name, image_ref:@image.id, flavor:@flavor.id}
    if @newNICs.length > 0
      @noPortsDefined = false
      data.nics = []
      for nic, i in @newNICs
        data.nics.push({uuid:nic})
    data.key_name = @key_name if @key_name && @key_name isnt "none"
    data.security_group = @security_group if @security_group && @security_group isnt "none"
    return data

  # Deploy a Server
  #
  deploy: ->
    unless @deployStatus == "deployed"
      rest.postRequest('/openstack/servers', @createData(), (resp) =>
        this.setDataFromOpenstackData(resp['server'])
        super()
        this.poll("ACTIVE")
      )

  # Terminate a Server
  #
  terminate: ->
    if @deployStatus is "undeployed"
      super()
    else
      rest.deleteRequest("/openstack/servers/#{@id}", (resp) =>
        super()
      )
    
  # Pause this Server
  #
  pause: ->
    this.action('pause', 'PAUSED')
    
  # Unpause this Server
  #
  unpause: ->
    this.action('unpause', 'ACTIVE')
    
  # Reboot this Server
  #
  reboot: ->
    this.action('reboot', 'ACTIVE')
    
  # Suspend this Server
  #
  suspend: ->
    this.action('suspend', 'SUSPENDED')
    
  # Resume this Server
  #
  resume: ->
    this.action('resume', 'ACTIVE')
    
  # Start this Server
  #
  start: ->
    this.action('start', 'ACTIVE')
    
  # Stop this Server
  #
  stop: ->
    this.action('stop', 'SHUTOFF')
  # Build a post request to perform an action on a server
  #
  # @param action [String] The action to perform e.g. 'suspend'
  # @param expected_result [String] The expected result of performing this action e.g. 'SUSPENDED'
  #
  action: (action, expected_result) ->
    rest.postRequest("/openstack/servers/#{@id}/action", {action:action}, this.actionDataHandler(expected_result)) if @deployStatus == "deployed"
    
  # Get VNC Console
  #
  vnc: ->
    rest.postRequest("/openstack/servers/#{@id}/action", {action:'vnc'}, (resp) ->)

  # Create a snapshot of this server
  #
  # @param callback []
  #
  snapshot: (callback) ->
    d = new Date()
    rest.postRequest("/openstack/servers/#{@id}", {action:snapshot, imageName:@name, metadata:{}}, callback)

  # Attach a volume to this server
  #
  # @param volume [Object] The volume object to connect to
  # @param link [Object] The Link object connecting the server and volume
  #
  attachVolume: (volume, link) ->
    rest.postRequest("/openstack/servers/#{@id}/attach_volume", {volume_id:@volume.id}, (resp) => link.setCommitted())

  # Begin a poll until the status is the expected result
  #
  # @param status [String] The expected result and point at which to stop the poll
  #
  poll: (status) ->
    server = this
    $.when(
      rest.getRequest("/openstack/servers/#{@id}", (resp) =>
        @setDataFromOpenstackData(resp['server'])
      )
    ).then(=>
      switch server.status
        when status
          if status is "ACTIVE"
            this.fireAction(Nodes.Server.PORTS_CHANGED)
          else
            @noPortsDefined = true
        when "ERROR" then console.log "Server #{@id} has errored!"
        else
          setTimeout((=> @poll(status)), 1500)
    )

  # The action data handler
  #
  # @param status [String] The expected result and point at which to stop the poll
  # @return [Object] The response
  #
  actionDataHandler: (status) ->
    return (resp) => poll(status)
