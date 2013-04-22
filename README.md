Curvature - Javascript based Visualisation Tool and Dashboard For OpenStack
==========================================================================

To run your own copy of the software, take the folder Server and place it into where you wish to
launch the app.

Open the folder, and in a text editor of your choice open /Server/config/curvature.yml 

Replace the keystone ip and port with the access location of your keystone server and save.

Now make sure you are in the /Server directory and run the command 'rails server' 
(You can customise the port by adding "-p myport"  where "myport" is the actual port number you want to run the server on.)
(You can run the server in daemon mode by adding -d, server output is then stored under /logs)


----------------------------------

Installing Rails  

Follow the instructions on the Ruby on Rails website. If you run into any problems, it is most likely that you need to install NodeJS, and the SQLite3 developement packages.  
  
sudo apt-get install nodejs libsqlite3-dev  
  
then cd into the Server directory and  
  
bundle install  
  
bundle exec rake db:drop  
bundle exec rake db:create  
bundle exec rake db:migrate  
  
rails server  

----------------------------------

Developer Infomation  
  
The project is built roughly as two distinct components, the Rails server, and our HTML5 frontend.

The Rails server is responsible for handling all API calls to OpenStack itself, a required step for same-site-security issues. It also stores cookie, and template data in its database. Note that apart from cookie data, the server stores no infomation on the state of openstack itself and acts simply as a pass thru.  

The front end is everything you see on the page. Our system is built with minimum page refreshes, prefering instead to ajax data in on the fly. All deployment logic is built here (waiting for dependancies to go up and such), and is built 100% asychronously.  

Directory Structure  

The directory is built like any other Rails project (which you probably know before jumping into this). Areas of particular interest.

/Config 
  - Contains all configuration files, most importantly curvature.yml and routes.rb

/App/Controllers
  - Contains the controllers for our views
  - application_controller.rb logins_controller.rb, rest_controller.rb and quantum_rest_controller provide our API to the javascript frontend, everything else is for templateing. logins_controller.rb handles cookie data.

/App/Models
  - Contains database schemas for cookies and templating.

/App/Views
  - Contains our views, root page in logins, and our main page (sans resources) is in visualisation, everything else is for our API, or templating.

/Public
  - Contains all static elements. For us is where all of our application resources and javascript sit, further explaination of this directory is in the folder itself.




