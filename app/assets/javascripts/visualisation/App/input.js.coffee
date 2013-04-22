# 
#  input.js.coffee
#  Input from mouse and keyboard handlers
#

# ===================================================================
# =                           Mouse Input                           =
# ===================================================================
# Detect collisions between the mouse(XY) and D3 objects
@mouseX = 0
@mouseY = 0

# The distance in pixels around a click that nodes will be picked up
CLICK_OFFSET = 20

# Detect a collision between the mouse and a link between nodes
@linkCollision = ->  
  # Calculate midpoints for all links
  mid = []
  for l of links
    mid.push midpoint(l.source.x, l.source.y, l.target.x, l.target.y)
  
  # Compare midpoints to the mouse position + CLICK_OFFSET
  i = 0
  while i < mid.length
    return d3.selectAll(".link")[0][i]  if isCoordInCircle(mid[i].x, mid[i].y, CLICK_OFFSET)
    i++
  false

# Calculate the midpoint of a line given
@midpoint = (x1, y1, x2, y2) ->
  x = (x1 + x2) / 2
  y = (y1 + y2) / 2
  x: x
  y: y

# Check to see if a point is inside a circle (inside the mouse click area)
@isCoordInCircle = (x, y, radius) ->
  sqr = (n) ->
    n * n
  distance = Math.sqrt(sqr(x - mouseX) + sqr(y - mouseY))
  return true  if distance <= radius
  false


# ========================================================================
# =                           Keyboard Events                            =
# ========================================================================
document.onkeydown = (e) ->
  keyPress = event.keyCode
  
  switch keyPress    
    # ESC
    when 27
      # On escape [ESC] press if the links tool is selected clear the current proposed links
      #clearTemporary true  if document.body.style.cursor is "link" #graphInteractions.js  
      break
    #R
    when 82    
      # On R set the current tool to Remove Tool
      break
    #M9.99
    when 77     
      # On M set the current tool to the move tool
      break
    #L
    when 76    
      # On L set the current tool to the link tool
      break
    #Alt
    when 18
      $("#controlsOverlay")[0].style.visibility = "visible"

#return false;   // Prevents the default action
document.onkeyup = (e) ->
  keyPress = event.keyCode  
  switch keyPress     
    #Alt
    when 18
      $("#controlsOverlay")[0].style.visibility = "hidden"  
