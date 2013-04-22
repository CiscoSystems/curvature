window.onload = ->
  @curvy = new App.Curvature()
  curvy.restartPage()

# ========================================================================================
# =                           Jquery UI element initialisation                           =
# ========================================================================================

# Set generic Dialog Box
#
@genericDialog = (divId) ->
  $("##{divId}").dialog
    autoOpen: false
    hide: "explode"
    show: "blind"
    modal: true
    width: 350
    height: 250

# Initialise JQuery UI Elements
#
jQuery ->

  genericDialog "dialog"
  genericDialog "import"
  genericDialog "manage"
  genericDialog "editContainer"
  genericDialog "vncConsole"
  genericDialog "aboutDialog"
  genericDialog "errorDialog"

  $('#moreDetails').on("click", ->
    console.log('CLICK CLAK')
    $('#errorDetails').toggle('blind')
  )

  $("#floatingIpDialog").dialog
    autoOpen: false
    hide: "explode"
    modal: true
    buttons: [
      text: "Done"
      click: ->
        $(this).dialog "close"
    ]

  $('#allocateFloatingIp').click(=>
    ext_net = $('#floatingIpDialog').data('node')
    $.when(App.openstack.floatingIps.create(ext_net)).done(=>
      curvy.populateTableWithFloatingIps(ext_net)
    )
  )

  $("#securityRuleDialog").dialog
    autoOpen: false
    hide: "explode"
    width: 800
    modal: true
    buttons: [
      text: "Back to Security Groups"
      click: ->
        $(this).dialog "close"
        curvy.showSecurityGroupDialog()
    ,
      text: "Return to Graph"
      click: ->
        $(this).dialog "close"
    ]

  $("#keyPairDialog").dialog
    autoOpen: false
    hide: "explode"
    width: 800
    modal: true
    buttons: [
      text: "Return to Graph"
      click: ->
        $(this).dialog "close"
    ]

  $('#newKPButton').click(=>
    $.when(
      App.openstack.keypairs.new($('#kpName').val())
    ).done(=>
      curvy.populateKeyPairDialog()
    )
  )

  $("#securityGroupDialog").dialog
    autoOpen: false
    hide: "explode"
    width: 800
    modal: true
    buttons: [
      text: "Return to Graph"
      click: ->
        $(this).dialog "close"
    ]

  $("#addImageDialog").dialog
    autoOpen: false
    hide: "explode"
    modal: true
    buttons: [
      text: "Create Image"
      click: (e) ->
        $("#newImageLoading").show()
        $("#createImageButton").attr "disabled", "disabled"
        $.when(
          App.openstack.images.newImage $('#imageName')[0].value, $('#imageInput'), $('#imageFormat')[0].value, $('#minDisk')[0].value, $('#minRam')[0].value,$('#imagePublic')[0].value
        ).then( () ->
          $("#createImageButton").removeAttr 'disabled'
          $("#newImageLoading").hide()
          $("#addImageDialog").dialog 'close'
          $.when(
            App.openstack.images.populate()
          ).then( () ->
            setupImages()
          )
        )
        $(this).dialog "close"
    ,
      text: "Cancel"
      click: ->
        $(this).dialog "close"
    ]

  $("#newNetwork").dialog
    autoOpen: false
    hide: "explode"
    modal: true
    buttons: [
      id: "editNetwork"
      value: ""
      text: "Save"
      click: =>
        $("#newNetwork").data('node').name = $("#newNetworkName").val()
        $("#newNetwork").data('node').cidr = $("#newNetworkCIDR").val()
        console.log $("#newNetwork").data('graph')
        if $("#newNetwork").data('graph') instanceof D3.ContainerVisualisation
           $("#newNetwork").data('node').temp_id = $("#newNetwork").data('graph').nodes.createUUID()
        $("#newNetwork").data('graph').nodes.newNode($("#newNetwork").data('node'), false, curvy.networkVisualisation.mouse.x, curvy.networkVisualisation.mouse.y)
        $("#newNetwork").data('graph').force.start()
        console.log $("#newNetwork").data('node')
        $("#newNetwork").dialog "close"
    ,
      text: "Random"
      click: ->
        if $("#newNetwork").data('graph') instanceof D3.ContainerVisualisation
          document.getElementById("newNetworkCIDR").value = "random"
        else
          document.getElementById("newNetworkCIDR").value = "" + Math.floor(Math.random() * 256) + "." + Math.floor(Math.random() * 256) + "." + Math.floor(Math.random() * 256) + ".0/24"
    ,
      text: "Cancel"
      click: ->
        $(this).dialog "close"
        ##App.openstack.subnets._data.pop(index) TODO Remove from openstack object.
        console.log $("#newNetwork")
        
        if not $("#newNetwork").dialog().data('node').cidr?
          $("#newNetwork").dialog().data('node').terminate()
    ]
    open: ->
      if $("#newNetwork").data('graph') instanceof D3.ContainerVisualisation
        document.getElementById("newNetworkCIDR").value = "random"
    

  $("#subnet").dialog 
    autoOpen: false
    hide: "explode"
    modal: true
    buttons: [
      id: "editSubnet"
      value: ""
      text: "Save"
      click: =>
        $("#subnet").data('node').cidr = $("#subnetCIDR").val()
        $("#subnet").dialog "close"
    ,
      text: "Random"
      click: ->
        document.getElementById("subnetCIDR").value = "" + Math.floor(Math.random() * 256) + "." + Math.floor(Math.random() * 256) + "." + Math.floor(Math.random() * 256) + ".0/24"
    ,
      text: "Cancel"
      click: ->
        $(this).dialog "close"
        ##App.openstack.subnets._data.pop(index) TODO Remove from openstack object.
        console.log $("#subnet")
        
        if not $("#subnet").dialog().data('node').cidr?
          window.curvy.networkVisualisation.removeNode($("#subnet").dialog().data('node'))
    ]

  $("#newContainer").dialog
    autoOpen: false
    hide: "explode"
    modal: true
    buttons: [
      id: "newContainer"
      value: ""
      text: "Save"
      click: ->

        name = $("#containerName").value
        createContainer name
        
        $(this).dialog "close"
    ,
      text: "Cancel"
      click: ->
        $(this).dialog "close"
    ]

  $("#vm").dialog
    autoOpen: false
    hide: "explode"
    width:500
    modal: true
    buttons: [
      id: "editVM"
      value: ""
      text: "Save"
      click: ->
        $("#vm").data('node').name = $("#vmNAME").val()
        $("#vm").data('node').flavor.id = $("#vmFlavor").val()
        $("#vm").data('node').key_name = $("#vmKeypair").val()
        $("#vm").data('node').security_group = $("#vmSecurityGroup").val()
        $(this).dialog "close"
    ,
      text: "Cancel"
      click: ->
        $(this).dialog "close"
    ]

  $("#vmAssociate").click(=>
    vals = JSON.parse($("#vmFloating").val())
    id = vals.fip
    port = vals.port
    $.when(App.openstack.floatingIps.update(id, port)).done(=>
      curvy.populateServerFloatingIpStuff($("#vm").data('node'))
    )
  )

  $("#router").dialog
    autoOpen: false
    hide: "explode"
    modal: true
    buttons: [
      id: "editRouter"
      value: ""
      text: "Save"
      click: ->
        $("#router").data('node').name= $("#routerNAME").val()
        $(this).dialog "close"
    ,
      text: "Cancel"
      click: ->
        $(this).dialog "close"
    ]

  $("#containerEditor").dialog
    autoOpen: false
    hide: "explode"
    modal: true
    width: 800,
    height: 500,
    buttons: [
      id: "updateContainerButton"
      text: "Update Container"
      click: =>
        ##SAVE CONTAINER CODE
        $.when(
          @containerBuilder.saveContainer($("#containerEditor").data('containerID'))
          $("#containerEditor").dialog "close"
        ).done( () ->
          $.when (
            App.donabe.containers.populate()
          ).then( () ->
            curvy.setupContainers()
          )
        )
    ,
      id: "saveContainer"
      text: "Save New Container"
      click: =>
        ##SAVE CONTAINER CODE
        $.when(
          @containerBuilder.saveContainer(null)
          $("#containerEditor").dialog "close"
        ).done( () ->
          $.when (
            App.donabe.containers.populate()
          ).then( () ->
            curvy.setupContainers()
            if curvy.networkVisualisation.tools.currentlyShowing is 'containers'
              curvy.networkVisualisation.tools.drawTools('containers')
          )
        )
    ,
      text: "Cancel"
      click: ->
        $(this).dialog "close"      
    ]
    open: =>
      $("#updateContainerButton").button("disable")
      @containerBuilder = new D3.ContainerVisualisation('D3containerEditor')
      console.log @containerBuilder
      if $("#containerEditor").data('containerID') != null
        $("#updateContainerButton").button("enable")
        @containerBuilder.displayExistingContainer($("#containerEditor").data('containerID'))
    beforeClose: =>
      $(".D3containerEditor").children('svg').remove()
      $("#containerEditor").data('containerID', null)
      @containerBuilder = null
  ###
  $("#zoomSlider").slider
    orientation: "vertical"
    min: 1
    max: 15
    value: 10
    slide: (event, ui) ->
      zoomGraph ui.value
  ###
  
  $("#liveContainerViewer").dialog
    autoOpen: false
    modal: true
    width: 800,
    height: 500,
    buttons: [
      text: "Back"
      click: ->
        if document.liveContainer.levels.length > 1
          console.log document.liveContainer.levels.pop()
          document.liveContainer.displayLiveContainer(document.liveContainer.levels[document.liveContainer.levels.length - 1 ])
        else
          $(this).dialog "close"  
    ,
      text: "Close"
      click: ->
        $(this).dialog "close" 
 
    ]
    open: =>
      console.log "SAASASASASAS"
      console.log this
      @liveContainer = new D3.LiveContainerVisualisation('D3containerViewer')
      console.log @liveContainer
      @liveContainer.displayLiveContainer($("#liveContainerViewer").data('containerID'))
    close: =>
      $(".D3containerViewer").children('svg').remove()
      $("#liveContainerEditor").data('containerID', null)
      @liveContainer = null

  $("#LogoutButton").button()

  # Overview Tab Sliders 
  $("#instancesSlider").progressbar value: 0
  $("#cpusSlider").progressbar value: 0
  $("#ramSlider").progressbar value: 0
  
  $("#noNetworks").dialog
    autoOpen: false
    hide: "explode"
    modal: true
    buttons: [
      text: "OK"
      click: ->
        $(this).dialog "close"
    ]

  $("#graph").mouseout ->
    document.getElementById("graph").style.cursor = "inherit"

  # Tooltips 
  $(document).tooltip position:
    my: "left+10 center"
    at: "right center"


  $("#toolTabs").tabs()
  $("#toolTabsContainer").tabs()
  $("#toolTabsContainerViewer").tabs()
  
