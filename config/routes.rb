Rails.application.routes.draw do
  resources :users do
    resources :environments
  end

  resource :meta, :only => [:show]

  resource :login, :except => [:new, :edit, :update] do
    get 'refresh', :on => :collection
  end

  get '/logout', to: 'logins#destroy', as: :logout

  get '/signup', to: 'users#new', as: :signup 

  root 'logins#show'

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
    resources :networks, :subnets, :images, :only => [:index, :create, :destroy]
    resources :floating_ips

    resources :flavors, :volumes, :only => :index
  end
end
