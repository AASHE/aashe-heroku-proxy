# aashe-heroku-proxy

AASHE Microsite Proxy Server

## Heroku

This is hosted on Heroku and deployed using Docker. 

You must install the Docker add-on on the Heroku instance by executing:

    heroku plugins:install heroku-docker

Note: This requires a "verified" account.

## Initialization

Note: This does not need to be done again, the result is stored in this repository. 
I am simply documenting what I did in case I ever need to do it again.


You must first create two files in your project directory.

app.json contains info about your app. The image attribute is required, something
that is not documented elsewhere.

    {
      "name": "AASHE Proxy",
      "description": "A load balancer for proxying AASHE microsites",
      "image": "heroku/cedar",
      "addons": [
        "heroku-postgresql"
      ]
    }

Procfile contains instructions for Heroku to deploy your app. It is always
the same:

    web: sbin/haproxy -f haproxy.cfg

After these files are created, execute:

    heroku docker:init

Open the Dockerfile and paste the contents of the Dockerfile in this repo into it.
These instruct the server how to download and compile haproxy.

After this is done, you will need to create an haproxy.cfg file similar to the one
stored in this repository.

## haproxy configuration

To add another server, first add a line to the "frontend http-in" section:

    use_backend [name of server backend later] if { path_beg /[root of your url patterns] }

Then, you must construct the backend section for this server:

    backend [name of server backend]
      http-request set-header X-Forwarded-Host aashe.org
      http-request set-header X-Forwarded-Port %[dst_port]

      reqirep ^Host: Host:\ [heroku app name].herokuapp.com

      server [heroku app name] [heroku app name].herokuapp.com:80

## Deployment with Docker

Deployment is easy. Simply execute:

    heroku docker:release

## nginx configuration

Finally, you need to add an entry to the nginx configuration file on sustain.

SSH in, then navigate to /etc/nginx/sites-enabled.

    $ sudo vi aashe-rc

Scroll down and you will find the entries for existing apps. Insert a new entry:

    location ~ ^/[root url of your url patterns](.*) {
                    rewrite ^/[root url of your url patterns](.*) /[root url of your url patterns]$1 break;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header Host $http_host;
                    proxy_set_header X-Forwarded-Proto https;
                    proxy_redirect off;
                    proxy_buffers 8 16k;
                    proxy_buffer_size 32k;
                    proxy_read_timeout 180s;
                    #resolver 8.8.8.8;
                    #resolver_timeout 60s;
                    set $backend "http://aashe-proxy.herokuapp.com";
                    #proxy_pass $backend;
                    proxy_pass http://aashe-proxy.herokuapp.com;
                }

