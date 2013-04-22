# Directory Structure For Javascript side

## /Visualisation
- *keyboard.js*, keyboard events handlers for shortcuts
- *page.js*, executed on page load, used to setup networks, tenants and initiate JQueryUI Objects
- *Rest.js*, startup rest calls. Stores global lists with current OpenStack state for later access.

## /Visualisation/Graph
- *d3-graph.js*, all of the D3 initialisation and code to actually draw changes to the graph
- *deploy.js*, file executed when the Deploy button is hit. Daisy chained asynchronous calls.
- *graphinteractions.js*, all code that involves interacting or editing the state of the D3 graphs (adding nodes/links, removing nodes, color changes etc.)
- *popups.js*, code for various popups used to set node details
- *svg.js*, some paths we use for drawing certain elements within D3
- *containers.js*, all logic for saving and retrieving containers
- *views.js*, code which will change what data D3 is displaying (changing networks)

## /Visualisation/Libraries
- *d3.v2.min.js*, D3 Library used for the graph
- *fisheye.js*, Extension to D3 to allow a fisheye zoom over the graph
- *jquery-1.8.0.min.js*
- *jquery-ui-1.9.1.custom.min.js*, UI elements from JQueryUI depends on theme files in /Visualisation/css/smoothness


## /Visualisation/Rest
- *basicRest.js*, container request functions and error handlers
- *createRest.js*, rest calls related to the creation of new objects
- *getRest.js*, calls for getting the current state of OpenStack
- *manipulation.js*, anything that changes the state of OpenStack but doesn't create anything, moving ports etc.
- *polling.js*, anything that polls OpenStack waiting for a specific action to happen
- *containersRest.js*, all the calls to the rails server so store and retrieve containers.
