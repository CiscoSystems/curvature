Installing Curvature in Production
==================================


Precompile the Assets 
---------------------
Precompile all the static assets to prevent rails compiling them on every request. 

    rake assets:precompile:all


Setup Apache
------------
Install apache modules:

    sudo a2enmod proxy
    sudo a2enmod proxy_balancer
    sudo a2enmod proxy_http
    sudo a2enmod rewrite

Create an Apache Virtual Host, this configuration will use Apache to serve all the static files, and unicorn for all the non-static application work. 

    <VirtualHost *:80>
      ServerName domain.com
      ServerAlias www.domain.com

      # Point at curvatures public folder
      DocumentRoot /opt/curvature/public

      RewriteEngine On

      <Proxy balancer://unicornservers>
        BalancerMember http://127.0.0.1:3000
      </Proxy>

      # Redirect all non-static requests to unicorn.
      RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
      RewriteRule ^/(.*)$ balancer://unicornservers%{REQUEST_URI} [P,QSA,L]

      ProxyPassReverse / balancer://unicornservers/
      ProxyPreserveHost on

      <Proxy *>
        Order deny,allow
        Allow from all
      </Proxy>

      # Custom log file locations
      ErrorLog  /opt/curvature/log/error.log
      CustomLog /opt/curvature/log/access.log combined

    </VirtualHost>

After setting up virtual hosts remember to restart apache. 

Starting Unicorn
----------------
Start the unicorn application server. 

    bundle exec unicorn -p 3000 -E production


Test Application Server
-----------------------
You can test if unicorn is working correctly by accessing http://localhost:3000 on the machine that Curvature is running on.


Test Apache Proxying
--------------------
Accessing this machine in a browser should now proxy the application, and you should see curvature without having a port number.
