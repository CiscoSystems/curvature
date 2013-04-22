require 'json'
require 'net/http'
require 'uri'

class NetworkDesignsController < ApplicationController

  # GET /network_design
  # GET /network_design.json
  def show
    @network_design = NetworkDesign.find(params[:id])

    respond_to do |format|
      format.html { render :file => "network_designs/show.json.erb" }
      format.json { render :file => "network_designs/show.json.erb" }
    end
  end
 
  # GET /network_designs
  # GET /network_designs.json
  def index
    @network_designs = NetworkDesign.all

    respond_to do |format|
      format.html { render :file => "network_designs/index.json.erb" }
      format.json { render :file => "network_designs/index.json.erb" }
    end
  end

  # GET /network_designs/new
  # GET /network_designs/new.json
  def new
    @network_design = NetworkDesign.new

    respond_to do |format|
      format.html 
      format.json { render :json => @network_design }
    end
  end

  # GET /network_designs/edit
  # GET /network_designs/edit.json
  def edit
    @network_design = NetworkDesign.find(params[:id])

    ############ Get an up to date list of images #########
    @images = Image.all
    # Empty the current image list
    @images.each do |i|
      i.destroy
    end

    # Define URL for Glance
    @resp_images = nova().images()
    
    # For each image that comes back from Glance, create a new image object
    @resp_images["images"].each do |i|
      @image = Image.new()
      # Define the image's name and ID
      @image.name = i["name"]
      @image.uuid = i["id"]
      @image.save
    end

    @images = Image.all
    ######################################################

    ############ Get an up to date list of flavors ###########    
    @flavors = Flavor.all
    # Empty the current flavor list
    @flavors.each do |f|
      f.destroy
    end

    @resp_flavors = nova().flavors()

    # For each flavor that comes back from Nova, create a new flavor object
    @resp_flavors["flavors"].each do |f|
      @flavor = Flavor.new()
      # Define the flavor's name and ID
      @flavor.name = f["name"]
      @flavor.uuid = f["id"]
      @flavor.save
    end

    @flavors = Flavor.all
    ##########################################################

    # If the network_design has a JSON body which hasn't yet been read
    # Read the JSON and create the network_design framework
    if @network_design.read == false
      @body = @network_design.body
      @body = @body.gsub("'",'"')
      @body = JSON.parse(@body)
      @body = @body["network design"]
      @body["routers"].each do |r|
        router = @network_design.routers.build()
        router.name = r["name"]
        if r["exnet"] == "true"
          router.exnet = true
        else
          router.exnet = false
        end
        router.temp_id = r["id"]
        router.save
      end
      @body["subnets"].each do |s|
        subnet = @network_design.subnets.build()
        subnet.name = s["name"]
        subnet.temp_id = s["id"]
        s["routers"].each do |r|
          router = subnet.connected_routers.build()
          router.router_id = r["id"]
          router.save
        end
        subnet.save
      end
      @body["vms"].each do |v|
        vm = @network_design.vms.build()
        vm.temp_id = v["id"]
        vm.vm_type = v["type"]
        v["subnets"].each do |s|
          subnet = vm.connected_subnets.build()
          subnet.subnet_id = s["id"]
          subnet.save
        end
        vm.save
      end
      # Mark the JSON as having been read
      @network_design.read = true
      @network_design.save
    end

    @names = Array.new

    # For each vm that already exists in the network_design
    @network_design.vms.each do |vm|
      # Check if the vm's name is already in the names list
      if !(@names.include?(vm.vm_type))
        # If it isn't, add it to the names list
        @names << vm.vm_type
      end
    end
  
    # For each type that is already defined in the network_design
    @network_design.types.each do |type|
      # Delete any entries in the names table that match existing types
      @names.delete_if {|x| x.eql?(type.name)}
    end

    # For each entry in the names table
    @names.each do |n|
      # Create a new type object and define its name
      @type = @network_design.types.build()
      @type.name = n
      @type.save
    end

  end
 
  # PUT /network_designs/1
  # PUT /network_designs/1.json
  def update
    @network_design = NetworkDesign.find(params[:id])
    @images = Image.all
    @flavors = Flavor.all

    if params[:body] != nil
      @network_design.read = false
    else
      @network_design.read = true
    end

    respond_to do |format|
      if @network_design.update_attributes(params[:network_design])
        updateVMs(@network_design)
        format.html { render :file => "network_designs/show.json.erb" }
        format.json { render :file => "network_designs/show.json.erb" }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @network_design.errors, :status => :unprocessable_entity }
      end
    end
  end

  
  def updateVMs(params)
    @network_design = NetworkDesign.find(params[:id])
    @types = @network_design.types.all
    @vms = @network_design.vms.all
    @images = Image.all

    # Update all associated vms when a network_design is updated
    @vms.each do |vm|
      @types.each do |type|
        if type.name.eql?(vm.vm_type)
          vm.image_id = type.image
          vm.flavor = type.flavor
          @images.each do |image|
            if vm.image_id.eql?(image.uuid)
              vm.image_name = image.name
            end
          end
          vm.save
        end
      end
    end

  end

  # POST /network_designs
  # POST /network_designs.json
  def create
    @network_design = NetworkDesign.new(params[:network_design])

    if params[:body] != nil
      @network_design.read = false
    else
      @network_design.read = true
    end

    respond_to do |format|
      if @network_design.save
        format.html { redirect_to edit_network_design_path(@network_design), :notice => 'NetworkDesign was successfully created.' }
        format.json { render :json => @network_design, :status => :created, :location => @network_design }
        format.js { redirect_to edit_network_design_path(@network_design), :notice => 'NetworkDesign was successfully created.' }
      else
        format.html { redirect_to visualisation_url, :notice => 'An error occurred when saving the network_design.' }
        format.json { render :json => @network_design.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /network_designs/deploy/1
  # POST /network_designs/deploy/1.json
  def deploy
    @deployed = DeployedNetworkDesign.new()
    @deployed = deployHelper(params[:id],params[:network],false)    

    respond_to do |format|
      if @deployed.save
        format.html { redirect_to deployed_network_design_path(@deployed), :notice => 'NetworkDesign Successfully Deployed.' }
        format.json { redirect_to deployed_network_design_path(@deployed), :notice => 'NetworkDesign Successfully Deployed.' }   
      else
 
      end
    end
  end

  def deployHelper(id,network,embedded)
    @network_design = NetworkDesign.find(id)
    @deployed = DeployedNetworkDesign.new()
    @deployed.network_design_id = id

    @network_design.routers.each do |router|
      r = @deployed.deployed_routers.build()
      deployed_router = quantum().create_router("Router")
      r.openstack_id = deployed_router["router"]["id"]
      r.temp_id = router.temp_id
      r.save
    end

    subnet_cidr = @network_design.subnet_cidr
    if subnet_cidr == "random"
      subnet_cidr = "" + rand(256).to_s + "." + rand(256).to_s + "." + rand(256).to_s + "." + "0/24"
    end
    s = @deployed.deployed_subnets.build()
    deployed_subnet = quantum().create_subnet(network,subnet_cidr)
    s.openstack_id = deployed_subnet["subnet"]["id"]
    s.cidr = @network_design.subnet_cidr
    s.save
    subnet_list = Array.new()
    subnet_list << s.openstack_id
   
    @network_design.vms.each do |vm|
      v = @deployed.deployed_vms.build()
      deployed_vm = nova().create_server(vm.vm_type,vm.image_id,vm.flavor,network)
      v.openstack_id = deployed_vm["server"]["id"]
      v.temp_id = vm.temp_id
      v.image_id = vm.image_id
      v.image_name = vm.image_name
      v.vm_type = vm.vm_type
      v.flavor = vm.flavor
      v.save
      port_initialized = false
      while !port_initialized
        ports = quantum().device_ports(v.openstack_id)
        begin
          port_id = ports["ports"].first["id"]
          port_initialized = true  
        rescue
        end
      end
      quantum().move_port_to_subnets(port_id,subnet_list)
    end

    @network_design.embedded_network_designs.each do |embedded_network_design|
      @to_be_deployed = NetworkDesign.find(embedded_network_design.embedded_network_design_id)
      deployHelper(@to_be_deployed.id,network,true)
    end

    if !embedded
      return @deployed
    else
      @deployed.save
    end

  end


  # DELETE /network_designs/1
  # DELETE /network_designs/1.json
  def destroy
    @network_design = NetworkDesign.find(params[:id])
    @network_design.destroy

    respond_to do |format|
      format.html { redirect_to visualisation_url }
      format.json { head :no_content }
    end
  end
end
