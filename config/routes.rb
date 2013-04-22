Server::Application.routes.draw do
  resource :visualisation, :only => :show

  namespace :network_designs do
  end

  namespace :donabe do
    resources :containers
    resources :deployed_containers
  end
  #resources :network_designs do
    #resources :types
    #resources :vms do
    #  resources :connected_subnets
    #end
    #resources :routers
    #resources :subnets do
    #  resources :connected_routers
    #end
  #end
  
  resource :login, :only => [:show, :create] do
    collection do
      post 'switch'
      get 'tenants', 'current', 'services'
    end
  end
  match '/logout' => 'logins#destroy', :via => :get

  namespace :openstack do 
    resources :servers, :except => [:new, :edit, :update] do
      get 'quotas', :on => :collection
      post 'action', 'attach_volume', 'detach_volume', :on => :member
    end

    resources :security_groups do
      resources :rules, :only => [:create, :destroy]
    end

    resources :routers, :only => [:index, :create, :destroy] do
      resources :router_interfaces, :only => [:create, :destroy]
      resource :router_gateway, :only => [:create, :destroy]
    end

    resources :ports, :only => [:index, :create, :destroy] do
      post 'move_port', :on => :member
    end

    resources :keypairs do
      get 'download', :on => :member
    end
    resources :floating_ips
    resources :networks, :subnets, :images, :only => [:index, :create, :destroy]
    resources :flavors, :volumes, :only => :index
  end

  root :to => 'logins#show'
end
