Curvature - JavaScript based Visualization Tool and Dashboard For OpenStack
==========================================================================

What is Curvature
-----------------

Curvature is an interactive visualization tool and dashboard for
Openstack clouds. It uses javascript and is written using the Rails
framework. It leverages Javascript libraries like D3. 

Running Curvature
-----------------

To run your own copy of the software, take the folder Server and place it into where you wish to launch the app. You will need to have installed Ruby On Rails to proceed, so follow the instructions below in order to do that.

Open the folder, and in a text editor of your choice open /Server/config/curvature.yml 

Replace the OpenStack Keystone IP Address and Port with the access location of the Keystone Server in your cluster and save the file.

To start the server make sure you are in the curvature root directory and run the command 'rails server' 
(You can customize the port by adding "-p myport"  where "myport" is the actual port number you want to run the server on.)
(You can run the server in daemon mode by adding -d, server output is then stored under /logs)

Installing The Environment
--------------------------

In order to install the correct version of ruby (1.9.3) we recommend using RVM simply type into a terminal:

curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3 --gems=rails

If curl is not installed run 

sudo apt-get install curl

In order to now use rvm restart your terminal and change your terminal preferences to run command as login shell. If using gnome-terminal in Ubuntu instructions on how to do this can be found here https://rvm.io/integration/gnome-terminal

If you run into any problems, it is most likely that you need to install the SQLite3 development packages.  
  
sudo apt-get install libsqlite3-dev  


  
In the curvature directory run: 
  
bundle install  
  
(bundle exec) rake db:create  
(bundle exec) rake db:migrate  
  
rails server  

Developer Information  
---------------------

### Overview  

The project is built roughly as two distinct components, the Rails server, and our HTML5 frontend.

The Rails server is responsible for handling all API calls to OpenStack itself, a required step for same-site-security issues. It also stores cookie information for user login, but apart from that the server stores no infomation on the state of OpenStack itself and acts simply as a pass through.  

The HTML5 interface is what you see when loading the system in the browser, it is built with no refreshes in mind preferring instead to Ajax data in on the fly. All deployment logic is built here (waiting for dependencies to go up and keeping track of state), and is built 100% asynchronously.  

### Directory Structure  

The directory is built like any other Rails project (which you probably know before jumping into this). Areas of particular interest.

/config 
  - Contains all configuration files, most importantly curvature.yml and routes.rb

/app/controllers
  - Contains the controllers for handling the REST requests.
  - Subdirectory OpenStack encapsulates 

/app/models
  - Contains rails model for the cookies named Storages, the file here defines the data structure for the model.

/app/views
  - Contains our HTML page templates for logins and our main page is in the /visualisation directory along with partials for better DRY programming.

/app/assets
  - Contains subdirectories for stylesheets and JavaScript which are acted on my sockets (the asset pipeline) to compile CoffeeScript and SCSS into their true forms. 

/public
  - Contains all static elements. In the current state only the error pages exist in here, for example 404.html

Dependencies
------------

* ropenstack - A ruby Gem which abstracts the OpenStack APIs into an OO form.
* git
* ruby 1.9.3
* rails
* curl
