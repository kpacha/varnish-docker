varnish-docker
====

A minimal varnish container for mesos environments.

## Running outside mesos

Just run the docker image with your customized the env vars:

	docker run -it --rm -e "VARNISH_BACKEND_ADDRESS=140.211.11.105" \
	    -e "VARNISH_BACKEND_HOSTNAME=www.apache.org" \
	    -p 80:80 kpacha/varnish

## Running in mesos

If you have mesos-dns and bamboo, follow this simple steps:

+ associate the A Record of the backend app with the backend using bamboo, so bamboo will handle all the redirections
+ create a new app in the service group for the varnish instance. See below for an example.
+ associate the public A Record of your service to the varnish app, so bamboo will handle all the redirections

## Example

Create your backend app for the example service

	$ curl -iXPOST -d '{
	      "id": "example/http",
	      "cmd": "python -m SimpleHTTPServer \$PORT",
	      "mem": 50,
	      "cpus": 0.1,
	      "instances": 1,
	      "constraints": [
	        ["hostname", "UNIQUE"]
	      ]
	    }' http://marathon.mesos:8080/v2/apps

Associate the A Record of the new app with the app itself in the bamboo config

	$ curl -iXPOST -d '{"id":"/example/http","acl":"hdr(host) -i http-example.marathon.mesos"}' \
	    http://slave.mesos:8000/api/services


Create the varnish app for the example service

	$ curl -iXPOST -d '{
	      "id": "example/varnish",
	      "mem": 300,
	      "cpus": 0.5,
	      "instances": 2,
	      "constraints": [
	        ["hostname", "UNIQUE"]
	      ],
	      "container": {
	        "type": "DOCKER",
            "network": "BRIDGE",
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 0,
                    "servicePort": 0
                }
            ],
	        "docker": {
	          "image": "kpacha/varnish"
	        }
	      },
	      "env": {
	        "VARNISH_BACKEND_ADDRESS": "\$HOST",
	        "VARNISH_BACKEND_HOSTNAME": "http-example.marathon.mesos",
	      }
	    }' http://marathon.mesos:8080/v2/apps

Associate the public A Record of the service with the varnish app in the bamboo config

	$ curl -iXPOST -d '{"id":"/example/varnish","acl":"hdr(host) -i www.example.com"}' \
	    http://slave.mesos:8000/api/services

## Tips

### Single backend

It's recommended to set the `VARNISH_BACKEND_ADDRESS` env var to `$HOST` so each one of the varnish instances use the nearest HAProxy instance as a single backend.

Using the A Record of the backend service directly would force you the define several probes and a director, messing the vcl and adding lots of complexity to the cache layer.

### Instance number

Set as many varnish instances as you require (the more instances you set, the higher service throughput you get) but remember, even when `marathon` is monitoring your apps, service discontinuations could happen if your app has just one instance and that instance fails, so the recommended min is 2.

## Configuration

The image use these environmental vars:

+ `VARNISH_BACKEND_ADDRESS`: single ip of the backend service or load balancer
+ `VARNISH_MEMORY`: amount of memory to allocate for caching
+ `VARNISH_BACKEND_PORT`: port of the backend service
+ `VARNISH_VCL_FILE`: path to the vcl file
+ `VARNISH_PROBE_INTERVAL`: interval between healthcheck requests
+ `VARNISH_PROBE_TIMEOUT`: timeout for the healthcheck requests
+ `VARNISH_GRACE_TIME`: max time for serving stale content

Check the Dockerfile for the default values