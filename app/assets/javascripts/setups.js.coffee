# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$("#port").change ->
  console.log "Port Changed"

  port = $("#port").value
  valid = true

  for s in port
    if !isFinite(s)
      valid = false

  if valid
    $("#submitBtn").toggle(true)
  else
    $("#submitBtn").toggle(false)

  return

$("#ipaddr").change ->
  console.log "IP address changed"

  validate = $("#ipaddr").value

  if ValidateIPaddress validate
    $("#submitBtn").toggle(true)
  else
    $("#submitBtn").toggle(false)

  return

ValidateIPaddress = (inputText) ->
  ipformat = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
  if inputText.value.match(ipformat)
    true
  else
    false
