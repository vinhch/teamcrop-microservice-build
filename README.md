# Teamcrop Microservice Build #
Use `job.sh` to build all docker based services in Teamcrop.com.

As Teamcrop is using microservice archirtect, automatically build project and push to private registry is a must.

This script will clone a git repo, do some pre-processing (remove un-used files, directories such as build config, readme, test cases; composer update...), build new docker image and push to private registry.

All services (repo url & docker image) can be hardcode in `job.ini`.

## Service config in `job.ini`
All services can be config in `job.ini` files with `repo` and `image` lines. Each service info must be put in service section, such as:

```bash
[service1]
repo = git@bitbucket.org/service1.git
image = privateregistry.com:5000/service1

[service2]
repo = git@bitbucket.org/service2.git
image = privateregistry.com:5000/service2

...
```

## Build task
All tasks are documented & marked in `job.sh`, you can remove or add more task as you want based on your build flow.

## Build Flow
- Create new working directory with name 'section-Y-m-d-H-M-S-N' in directory `workspace`.
- Copy directory `dockerbuild` to working directory
- Clone repo source code to created `dockerbuild` in working directory under directory `www`.

## Working with `Dockerfile`
Our microservices are based on nginx and php-fpm, so all docker images will build from my custom docker-nginx-php image from `voduytuan/docker-nginx-php`. Learn more about this image (include source code directory, port, log...) at docker hub: [https://hub.docker.com/r/voduytuan/docker-nginx-php/](https://hub.docker.com/r/voduytuan/docker-nginx-php/)

In building process, script will copy all repo source code to image (instead of mount volume).

In `dockerbuild` directory, there is a file called `startup.sh`. I used this script as ENTRYPOINT for our images because all teamcrop microservice images must come with a configuration, and this configuration will be download to container when this image started. If you do not need this process, just remove all lines from `startup.sh` file and replace with:

```bash
#!/bin/bash
/sbin/my_init
```

## Running:
This script require one argument in command line as section (defined in `job.ini` file)

```bash
$ ./job.sh service-01
```


## Supervisord & Collectd
The dockerfile and startup script come with install Supervisord and Collectd to collect system, network information and push to an predefined url (every 10s) in environment with name COLLECTD_WRITEHTTP_HOST, such as "docker run ... -e COLLECTD_WRITEHTTP_HOST=http://yourreceiveurl...


