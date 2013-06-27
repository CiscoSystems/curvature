# Curvature object, this is the main entry point for the program and
# contains all code related to specific GUI elements e.g. setting
# up network tabs
#
class App.Curvature
  # @property [Object] The instance of network visualisation to display networks
  networkVisualisation: Object
  # @property [Object] The instance of deploy
  deploy: Object

  # Construct a new instance of Curvature and setup instance variables
  #
  constructor: () ->
    @networkVisualisation = new D3.Visualisation('D3Graph')
    @deploy = new App.Deploy()

  # Code to restart the page on a change.
  #
  # Will repopulate the openstack data and redraw the page
  #
  restartPage: () ->
    @networkVisualisation.clearGraph()
    _this = this
    $.when(
      App.openstack.tenants.populate(),
      App.openstack.flavors.populate(),
      App.openstack.images.populate(),
      App.openstack.quotas.populate(),
      App.openstack.currentTenant.populate(),
      App.openstack.services.populate(),
      App.openstack.keypairs.populate(),
      App.openstack.securityGroups.populate()
    ).then( () ->
      $('body,html').css('visibility','visible')
      console.log App.openstack.services.get()
      _this.setupTenants()
      _this.setupFlavorsDropdown()
      _this.setupImages()
      _this.displayQuotas()
      if App.openstack.services.get().indexOf("donabe") >= 0
          donabeActive = true

      if donabeActive
        $.when(
          App.donabe.containers.populate()
          App.donabe.deployed_containers.populate()
        ).then( () ->
          _this.setupContainers()
        )
      $.when(
        App.openstack.networks.populate()
        App.openstack.floatingIps.populate()
      ).then(() ->
        _this.networkTabs()

        openstackPromises = [App.openstack.subnets.populate(), App.openstack.ports.populate()]

        if App.openstack.services.get().indexOf("cinder") >= 0
          openstackPromises.push(App.openstack.volumes.populate())

        $.when.apply(this, openstackPromises).then(() ->
          $.when(
            App.openstack.servers.populate(),
            App.openstack.routers.populate()
          ).then(->
            if App.openstack.services.get().indexOf("cinder") >= 0
              _this.setupVolumes()
            _this.networkVisualisation.displayAllNetworks()

          )
        )
      )

    )

  # =============================================================================
  # =                              GUI Functionality                            =
  # =============================================================================

  # Show or Hide the labels for every node (works like a toggle)
  #
  showLabels: ->
    if $('.nodeLabel').css('display') is 'none'
      $('.nodeLabel').show()
      $('#shLabels').text("Hide Node Labels")
    else
      $('.nodeLabel').hide()
      $('#shLabels').text("Show Node Labels")

  displayVNCConsole: (server) ->
    $.when(
      server.vnc()
    ).then((data) =>
      iframe = "<iframe width='800' height='640px' src='"+data['console']['url']+"''></iframe>"
      $("#vncConsole").html(iframe)
      $('#vncConsole').dialog('open')
    )

  # ====================================================================
  # =                           NETWORK TABS                           =
  # ====================================================================

  # Delete a network
  #
  # @param name [String] The network id of the network to be deleted
  #
  deleteNetwork: (network_id) ->
    $( "#dialog-confirm" ).dialog(
      resizable: false,
      height: 170,
      modal: true,
      buttons:
        "Delete network!": ->
          Nodes.Network.terminate(network_id)
          $( this ).dialog( "close" )
        Cancel: ->
          $( this ).dialog( "close" )
    )

  # Setup the network tabs for every network
  #
  networkTabs: ->
    foundNetworks = false

    for network in App.openstack.networks.internal.get()
        foundNetworks = true

    $("#menubar").menubar({autoExpand: true})
    $("#deployButton").button()


  # ===============================================================
  # =                           Tenants                           =
  # ===============================================================

  # Setup List of Tenants to popuplate the dropdown menu
  #
  setupTenants: ->
  	#Set the name based on current tenant
  	document.getElementById("currentProject").innerHTML = 'Current Project - ' + App.openstack.currentTenant.get()
	
  	list = document.getElementById("projectList")
  	list.innerHTML = ""
  	for tenant in App.openstack.tenants.get()
      opt = document.createElement("li")
      opt.setAttribute 'class', 'ui-menu-item'
      opt.setAttribute 'role', 'presentation'
      opt.innerHTML = "<a class='ui-corner-all' role='menuitem' href='#' onClick='window.curvy.switchTenant(\"#{tenant.name}\")'>#{tenant.name}</a>"
      list.insertBefore opt , list.lastChild
    
  	$("#menubar").menubar({
  		autoExpand: true
  	})
  
  # Switch to a different tenant
  #
  # @param name [String] The name of the tenant you want to switch to
  #
  switchTenant: (name) ->
    $.when(
      App.openstack.currentTenant.switch(name)
    ).then( => this.restartPage())

  # ===============================================================
  # =                        Containers                           =
  # ===============================================================

  # Setup all container relavent stuff.
  #
  setupContainers: ->
    # Setup Tools
    #@networkVisualisation.tools.listOfTools.containers.splice(0,@networkVisualisation.tools.listOfTools.containers.length)
    @networkVisualisation.tools.listOfTools.containers = []
    for container in App.donabe.containers.get()
      @networkVisualisation.tools.listOfTools.containers.push new Nodes.Container(container, "deployed")

    # Setup DropDowns
    list = document.getElementById("containerList")
    list.innerHTML = ""
    for container in App.donabe.containers.get()
      opt = document.createElement("li")
      opt.setAttribute 'class', 'ui-menu-item'
      opt.setAttribute 'role', 'presentation'
      opt.innerHTML = "<a class='ui-corner-all' role='menuitem' href='#' onClick='$(\"#containerEditor\").data(\"containerID\", "+container["id"]+");$(\"#containerEditor\").dialog(\"open\");'>"+container["name"]+"</a>"
      list.insertBefore opt , list.lastChild

    newButton = document.createElement("li")
    newButton.setAttribute 'class', 'ui-menu-item'
    newButton.innerHTML = "<a class='ui-corner-all' role='menuitem' href='#' onClick='$(\"#containerEditor\").data(\"containerID\", null);$(\"#containerEditor\").dialog(\"open\");'><b>New Container</b></a>"
    
    list.insertBefore newButton, list.lastChild

    $("#menubar").menubar({
      autoExpand: true
    })

  # ==============================================================
  # =                           IMAGES                           =
  # ============================================================== 

  # Create buttons for the different images unless they are kernal images or ramdisks
  #
  setupImages: ->
    @networkVisualisation.tools.listOfTools.images.splice(0,@networkVisualisation.tools.listOfTools.images.length)
    for image in App.openstack.images.get()
      if (image.disk_format isnt "aki") and (image.disk_format isnt "ari")
        @networkVisualisation.tools.listOfTools.images.push image

    $('#VMButtonDiv').append '<button class=\"nodeButton\" onMouseDown=\"javascript:$(\'#addImageDialog\').dialog(\'open\');\">Add Image</button>'

  # Setup the dropdown that displays the flavours a VM can be
  #
  setupFlavorsDropdown: ->
    selectBox = $("#vmFlavor").html("")
    for flavor,i in App.openstack.flavors.get()
      option = "<option value='#{flavor.id}'>#{flavor.name}</option>"
      selectBox.append(option)


  # ===============================================================
  # =                           VOLUMES                           =
  # ===============================================================

  # Create buttons for volumes
  #
  setupVolumes: ->
    if $('#volumeTab').length == 0
      $('#toolName').append("<li id='volumeTab'><a href='#t' onClick='curvy.networkVisualisation.tools.drawTools(curvy.networkVisualisation.tools.listOfTools.volumes,\"volumes\")'>Volumes</a></li>")
      $('#toolTabs').tabs('refresh')
    @networkVisualisation.tools.listOfTools.volumes.splice(0, @networkVisualisation.tools.listOfTools.volumes.length)
    for volume in App.openstack.volumes.get()
      unless volume.attachments.length > 0
        @networkVisualisation.tools.listOfTools.volumes.push new Nodes.Volume(volume)


  # ==============================================================
  # =                           QUOTAS                           =
  # ==============================================================

  # Show or Hide the overview bars (works like a toggle)
  #
  showHideOverview: ->
    if $("#overviewsContainer").css("display") is "none"
      $("#overviewsContainer").show()
      $("#shOverview").text "Hide the Overview Bars"
    else
      $("#overviewsContainer").hide()
      $("#shOverview").text "Show the Overview Bars"

  # Populate the overview quotas sliders
  #
  displayQuotas: ->
    instancePer = (App.openstack.quotas.totalInstancesUsed() / App.openstack.quotas.maxTotalInstances()) * 100
    $("#instancesSlider").data().used = instancePer
    console.log @instancePie
    if @instancePie is undefined
      @instancePie = new D3.Quota("instancesSlider")
    #else
      #@instancePie.animate([{"percentage":instancePer},{"percentage":100 - instancePer}])
    $("#instanceText").html("Instances Used : " + App.openstack.quotas.totalInstancesUsed() + "/" + App.openstack.quotas.maxTotalInstances())

    cpuPer = (App.openstack.quotas.totalCoresUsed() / App.openstack.quotas.maxTotalCores()) * 100
    $("#cpusSlider").data().used = cpuPer
    if @cpusPie is undefined
      @cpusPie = new D3.Quota("cpusSlider")
    $("#cpusText").html("CPUs Used : " + App.openstack.quotas.totalCoresUsed() + "/" + App.openstack.quotas.maxTotalCores())

    ramPer = (App.openstack.quotas.totalRAMUsed() / App.openstack.quotas.maxTotalRAMSize()) * 100
    $("#ramSlider").data().used = ramPer
    if @ramPie is undefined
      @ramPie = new D3.Quota("ramSlider")
    $("#ramText").html("RAM Used : " + App.openstack.quotas.totalRAMUsed() + "MB/" + App.openstack.quotas.maxTotalRAMSize() + "MB")

  # =====================================
  # Floating IP, Security Groups, etc   =
  # =====================================

  releaseButtonClick: (id, ext_net) =>
    return =>
      $.when(App.openstack.floatingIps.destroy(id)).done(=>
        @populateTableWithFloatingIps(ext_net)
      )

  populateTableWithFloatingIps: (ext_net) =>
    $('#floatingIpTable tbody').empty()
    for fIp in App.openstack.floatingIps.get()
      if fIp.floating_network_id is ext_net.id
        associated = "----"
        unless fIp.port_id == null
          port = App.openstack.ports.get(fIp.port_id)
          associated = App.openstack.servers.get(port.device_id).name
        $('#floatingIpTable tbody').append("
          <tr>
            <td> #{fIp.floating_ip_address} </td>
            <td> #{associated} </td>
            <td> <button id=\"release-#{fIp.id}\"> Release </button> </td>
          </tr>")
        $("#release-#{fIp.id}").click(@releaseButtonClick(fIp.id, ext_net))

  showFloatingIpDialog: (ext_net) ->
    $('#floatingIpDialog').dialog().data 'node', ext_net
    @populateTableWithFloatingIps(ext_net)
    $('#floatingIpDialog').dialog('open')

  disassociateButtonClick: (id, vm) =>
    return =>
      $.when(App.openstack.floatingIps.update(id, null)).done(=>
        @populateServerFloatingIpStuff(vm)
      )

  populateServerFloatingIpStuff: (vm) =>
    selectBox = $("#vmFloating").html("")
    $('#vmFloatingTable tbody').empty()
    networkids = []
    portids = []
    for port in App.openstack.ports.get()
      if port.device_id is vm.id
        networkids.push(port.network_id)
        portids.push(port.id)
    extNets = []
    extPorts = []
    for port in App.openstack.ports.get()
      if port.device_owner is "network:router_interface" and port.network_id in networkids
        router = App.openstack.routers.get(port.device_id)
        unless router.external_gateway_info is null
          extNets.push(router.external_gateway_info.network_id)
          extPorts.push(portids[networkids.indexOf(port.network_id)])
    floatingIps = false
    for fIp in App.openstack.floatingIps.get()
      if fIp.floating_network_id in extNets
        port_id = extPorts[extNets.indexOf(fIp.floating_network_id)]
        if fIp.port_id is null
          floatingIps = true
          option = "<option value='{\"fip\":\"#{fIp.id}\", \"port\":\"#{port_id}\"}'>#{fIp.floating_ip_address}</option>"
          selectBox.append(option)
        else if fIp.port_id is port_id
          $('#vmFloatingTable tbody').append("
            <tr>
              <td> #{fIp.floating_ip_address} </td>
              <td> #{fIp.fixed_ip_address} </td>
              <td> <button id=\"disassociate-#{fIp.id}\"> Disassociate </button> </td>
            </tr>")
          $("#disassociate-#{fIp.id}").click(@disassociateButtonClick(fIp.id, vm))
    if floatingIps and vm.deployStatus is "deployed"
      $('#vmFloating').prop('disabled', false)
      $('#vmAssociate').prop('disabled', false)
    else
      $('#vmFloating').prop('disabled', 'disabled')
      $('#vmAssociate').prop('disabled', 'disabled')
      option = "<option value='none'>None Available</option>"
      selectBox.append(option)

  showServerDialog: (vm) ->
    $('#vm').dialog().data 'node', vm
    $('#vmNAME').val(vm.name)
    $('#vmFlavor').val(vm.flavor.id)

    keypairs = $("#vmKeypair").html("")
    for kp in App.openstack.keypairs.get()
      option = "<option value='#{kp.name}'>#{kp.name}</option>"
      keypairs.append(option)

    keyname = vm.key_name
    keyname ?= "none"
    if keyname is "none"
      option = "<option value='none'>none</option>"
      keypairs.append(option)
    $('#vmKeypair').val(keyname)

    securityGroups = $("#vmSecurityGroup").html("")
    for sg in App.openstack.securityGroups.get()
      option = "<option value='#{sg.id}'>#{sg.name}</option>"
      securityGroups.append(option)

    sgid = vm.security_group
    sgid ?= "none"
    if sgid is "none"
      option = "<option value='none'>none</option>"
      securityGroups.append(option)
    $('#vmSecurityGroup').val(sgid)

    @populateServerFloatingIpStuff(vm)

    if vm.deployStatus is "undeployed"
      $('#vmFlavor').prop('disabled', false)
      $('#vmKeypair').prop('disabled', false)
      $('#vmSecurityGroup').prop('disabled', false)
    else
      $('#vmSecurityGroup').prop('disabled', 'disabled')
      $('#vmFlavor').prop('disabled', 'disabled')
      $('#vmKeypair').prop('disabled', 'disabled')

    $('#vm').dialog('open')

  populateKeyPairDialog: ->
    $('#keyPairTable tbody').empty()
    for kp in App.openstack.keypairs.get()
      downloadbutton = ""
      downloadbutton = "<button id='download-#{kp.name}'> Download </button>" if kp.private_key
      $('#keyPairTable tbody').append("
        <tr>
          <td> #{kp.name} </td>
          <td> #{kp.fingerprint} </td>
          <td> #{downloadbutton} </td>
          <td> <button id='delete-#{kp.name}'> Delete </button> </td>
        </tr>")
      $("#download-#{kp.name}").click(@downloadKeyPairButton(kp)) if kp.private_key
      $("#delete-#{kp.name}").click(@deleteKeyPairButton(kp))

  downloadKeyPairButton: (kp) ->
    return =>
      kpDownload.location.href = "/openstack/keypairs/#{kp.name}/download"

  deleteKeyPairButton: (kp) =>
    return =>
      $.when(
        App.openstack.keypairs.delete(kp)
      ).done(=>
        @populateKeyPairDialog()
      )

  showKeyPairDialog: ->
    @populateKeyPairDialog()
    $('#keyPairDialog').dialog('open')


  populateSecurityGroupDialog: ->
    $('#securityGroupTable tbody').empty()
    for sg in App.openstack.securityGroups.get()
      $('#securityGroupTable tbody').append("
        <tr>
          <td> #{sg.name} </td>
          <td> #{sg.description} </td>
          <td> <button id=\"edit-#{sg.id}\"> Edit </button> </td>
          <td> <button> Delete </button> </td>
        </tr>")
      $("#edit-#{sg.id}").click(@sgEditDialogButton(sg))

  showSecurityGroupDialog: ->
    @populateSecurityGroupDialog()
    $('#securityGroupDialog').dialog('open')

  sgEditDialogButton: (sg) ->
    return =>
        $('#securityGroupDialog').dialog('close')
        @showSecurityGroupRuleDialog(sg)

  populateSecurityRulesTable: (sg) ->
    $('#securityRuleTable tbody').empty()
    for rule in sg.rules
      protocol = rule.ip_protocol || "Any"
      $('#securityRuleTable tbody').append("
        <tr>
          <td> #{protocol} </td>
          <td> #{rule.from_port} </td>
          <td> #{rule.to_port} </td>
          <td> #{rule.ip_range.cidr} </td>
          <td> <button id='delete-#{rule.id}'> Delete </button> </td>
        </tr>")
      $("#delete-#{rule.id}").click(@deleteRuleButton(sg, rule))

  deleteRuleButton: (sg, rule) ->
    return ->
      $.when(
        App.openstack.securityGroups.deleteRule(sg, rule.id)
      ).done(=>
        
      )

  showSecurityGroupRuleDialog: (sg) ->
    console.log sg
    $('#securityRuleDialog').dialog().data 'node', sg
    @populateSecurityRulesTable(sg)
    $('#securityRuleDialog').dialog('open')
