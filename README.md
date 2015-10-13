# Teamcrop Microservice Build #
Use `job.sh` to build all docker based services in Teamcrop.com.

As Teamcrop is using microservice archirtect, automatically build project and push to private registry is a must.

This script will clone a git repo, do some pre-processing (remove un-used files, directories such as build config, readme, test cases; composer update...), build new docker image and push to private registry.

All services (repo url & docker image) can be hardcode in `job.ini` or pass through command line options `-r` and `-i`.

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

## Repository source code
In pre-processing, the source code of repo must be clone to `dockerbuild` directory to prepare for add to docker image in `docker build` task.

Default, all source code of repository will be download to subdirectory `www` in `dockerbuild` directory.

## Working with `Dockerfile`
Our microservices are based on nginx and php-fpm, so all docker images will build from my custom docker-nginx-php image from `voduytuan/docker-nginx-php`. Learn more about this image (include source code directory, port, log...) at docker hub: [https://hub.docker.com/r/voduytuan/docker-nginx-php/](https://hub.docker.com/r/voduytuan/docker-nginx-php/)

In building process, script will copy all repo source code to image (instead of mount volume).

In `dockerbuild` directory, there is a file called `startup.sh`. I used this script as ENTRYPOINT for our images because all teamcrop microservice images must come with a configuration, and this configuration will be download to container when this image started. If you do not need this process, just remove all lines from `startup.sh` file and replace with:

```bash
#!/bin/bash
/sbin/my_init
```

## Example:
There are two ways to pass service config, 
via `-s` to load from `job.ini`:

```bash
$ ./job.sh -s=tc-inventory
```

or using `-r`, `-i` options to custom config of service:

```bash
$ ./job.sh -r=git@bitbucket.org:service1.git -i=registry:5000/service1
```


## Supervisord & Collectd
The dockerfile and startup script come with install Supervisord and Collectd to collect system, network information and push to an predefined url (every 10s) in environment with name COLLECTD_WRITEHTTP_HOST, such as "docker run ... -e COLLECTD_WRITEHTTP_HOST=http://yourreceiveurl...


