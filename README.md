# Scaleway Image Toolbox

This repository contains the tools, documentations, examples and contents for building, debug and running images on [Scaleway](https://www.scaleway.com/).


## Getting start

You can look the docker-based [hello-world](https://github.com/scaleway/image-helloworld) image.

See [Building images on Scaleway with Docker](http://www.slideshare.net/manfredtouron/while42-paris13-scaleway) presentation on Slideshare.


## Repository

This repository contains :

- Common scripts in [./skeleton-* directories](#how-to-download-the-common-scripts-on-a-target-image) used in the images (upstart, sysvinit, openrc, common helpers, etc)
- The [Builder](https://github.com/scaleway/image-tools/tree/master/builder)


## Official images built with **image-tools**

Official images are available when creating a new server

Type      | Name           | State    | Versions                   | Parent | Links
----------|----------------|----------|----------------------------|--------|---------
distrib   | Ubuntu         | released | 12.04, 14.04, 14.10, 15.05 | n/a    | [Source](https://github.com/scaleway/image-ubuntu)
distrib   | Debian         | released | wheezy                     | n/a    | [Source](https://github.com/scaleway/image-debian)
distrib   | Fedora         | released | 21                         | n/a    | [Source](https://github.com/scaleway/image-fedora)
distrib   | Alpine Linux   | released | 3.1                        | n/a    | [Source](https://github.com/scaleway/image-alpine)
distrib   | Arch Linux     | released | n/a                        | n/a    | [Source](https://github.com/scaleway/image-archlinux)
distrib   | Opensuse       | wip      | n/a                        | n/a    | [Source](https://github.com/scaleway/image-opensuse)
distrib   | Slackware      | wip      | n/a                        | n/a    | [Source](https://github.com/scaleway/image-slackware)
distrib   | Busybox        | wip      | n/a                        | n/a    | [Source](https://github.com/scaleway/image-busybox)
app       | Docker         | released | 1.5                        | ubuntu | [Source](https://github.com/scaleway/image-app-docker)
app       | Ghost          | released | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-ghost)
app       | Owncloud       | released | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-owncloud)
app       | Pydio          | released | 6                          | ubuntu | [Source](https://github.com/online-labs/image-app-pydio)
app       | Wordpress      | released | 4                          | ubuntu | [Source](https://github.com/online-labs/image-app-wordpress)
app       | Torrents       | released | 1                          | ubuntu | [Source](https://github.com/online-labs/image-app-torrents)
app       | OpenVPN        | wip      | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-openvpn)
app       | TimeMachine    | wip      | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-timemachine)
app       | SeedBox        | planned  | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-seedbox)
app       | Mesos          | planned  | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-mesos)
app       | Proxy          | planned  | n/a                        | n/a    | n/a
app       | LEMP           | released | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-lemp)
app       | Node.js        | released | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-node)
app       | Python         | released | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-app-python)
app       | Discourse      | wip      | n/a                        | ubuntu | [Source](https://github.com/scaleway/image-app-discourse)
app       | Gitlab         | wip      | n/a                        | ubuntu | [Source](https://github.com/scaleway/image-app-gitlab)
app       | Java           | released | n/a                        | ubuntu | [Source](https://github.com/scaleway/image-app-java)
service   | Try-it         | released | n/a                        | docker | [Source](https://github.com/scaleway/image-service-tryit)
service   | Rescue         | released | n/a                        | ubuntu | [Source](https://github.com/online-labs/image-service-rescue)
community | moul' dev      | private  | n/a                        | ubuntu | [Source](https://github.com/moul/ocs-image-devbox)
community | moul' bench    | private  | n/a                        | ubuntu | [Source](https://github.com/moul/ocs-image-bench)
community | mxs' 3.2 perf  | private  | n/a                        | ubuntu | [Source](https://github.com/moul/ocs-image-bench)
community | mxs' 3.17 perf | private  | n/a                        | ubuntu | [Source](https://github.com/moul/ocs-image-bench)
community | Camlistore     | private  | n/a                        | ubuntu | [Source](https://github.com/aimxhaisse/image-app-camlistore)
community | Serendipity    | released | n/a                        | ubuntu | [Source](https://github.com/onli/image-app-serendipity)


# Builder

We use the [Docker's building system](https://docs.docker.com/reference/builder/) to build, debug and even run the generated images.

We added some small hacks to let the image be fully runnable on a C1 server without Docker.

The advantages are :

- Lots of available base images and examples on the [Docker's official registry](https://registry.hub.docker.com)
- Easy inheritance between images ([app-timemachine](https://github.com/online-labs/image-app-timemachine) image inherits from [app-openvpn](https://github.com/online-labs/image-app-openvpn) image which inherits from [ubuntu](https://github.com/online-labs/image-ubuntu) image)
- Easy debug with `docker run ...`
- A well-known build format file (Dockerfile)
- Docker's amazing builder advantages (speed, cache, tagging system)


## Install

The minimal command to install an image on an attached volume :

```bash
# write the image to /dev/nbd1
make install
```

## Commands

```bash
# Clone the hello world docker-based app on an armhf server with Docker
git clone https://github.com/scaleway/image-helloworld.git

# Run the image in Docker
make shell

# push the rootfs.tar on s3 (requires `s3cmd`)
make publish_on_s3 S3_URL=s3://my-bucket/my-subdir/

# push the image on docker registry
make release DOCKER_NAMESPACE=myusername

# remove build directories
make clean

# remove build directories and docker images
make fclean
```

Debug commands

```bash
# push the rootfs.tar.gz on s3 (requires `s3cmd`)
make publish_on_s3.tar.gz S3_URL=s3://my-bucket/my-subdir/

# push the rootfs.sqsh on s3 (requires `s3cmd`)
make publish_on_s3.sqsh S3_URL=s3://my-bucket/my-subdir/

# build the image in a rootfs directory
make build

# build a tarball of the image
make rootfs.tar

# build a squashfs of the image
make rootfs.sqsh
```

## Install builder's `.mk` files

```bash
# From a shell
wget -qO - https://raw.githubusercontent.com/scaleway/image-tools/master/builder/install.sh | bash
# or
wget -qO - http://j.mp/scw-builder | bash
```

Or from a Makefile ([example](https://github.com/scaleway/image-helloworld/blob/master/Makefile))

```Makefile
## Image tools  (https://github.com/scaleway/image-tools)
all:    docker-rules.mk
docker-rules.mk:
    wget -qO - http://j.mp/scw-builder | bash
-include docker-rules.mk
```


# Unit test a running instance

At runtime, you can proceed to unit tests by calling

```bash
# using curl
SCRIPT=$(mktemp); curl -s -o ${SCRIPT} https://raw.githubusercontent.com/scaleway/image-tools/master/builder/unit.bash && bash ${SCRIPT}
# using wget
SCRIPT=$(mktemp); wget -qO ${SCRIPT} https://raw.githubusercontent.com/scaleway/image-tools/master/builder/unit.bash && bash ${SCRIPT}
```

# Image check list

List of features, scripts and modifications to check for proper **scaleway** image creation.

- [ ] Add sysctl entry `vm.min_free_kbytes=65536`
- [ ] Configure NTP to use internal server
- [ ] Configure SSH to only accept login through public keys and deny environment customization to avoid errors due to users locale
- [ ] Configure default locale to `en_US.UTF-8`
- [ ] Configure network scripts to use DHCP and enable them
  Although not, strictly speaking, needed since kernel already has IP address and gateway this allows DHCP hooks to be called for setting hostname, etc
- [ ] Install custom DHCP hook for hostname to set entry in `/etc/hosts` for software using `getent_r` to get hostname
- [ ] Install scripts to fetch SSH keys
- [ ] Install scripts to fetch kernel modules
- [ ] Install scripts to connect and/or mount NBD volumes
- [ ] Install scripts to manage NBD root volume
- [ ] Disable all physical TTY initialization
- [ ] Enable STTY @ 9600 bps

Before making the image public, do not forget to check it boots, stops and restarts from the OS without any error (most notably kernel) since a failure could lead to deadlocked instances.


# How to download the common scripts on a target image

Those scripts are mainly used in the base image (distrib) but can sometimes be useful in the app images (inherited from distrib).o

An example of usage in the [Ubuntu image](https://github.com/scaleway/image-ubuntu/blob/9cd0f287a1977a55b74b1a37ecb1c03c8ce55c85/14.04/Dockerfile#L12-L17)

```bash
wget -qO - http://j.mp/scw-skeleton | bash -e

# Using upstart flavor
wget -qO - http://j.mp/scw-skeleton | FLAVORS=upstart bash -e
# Using sysvinit, docker-based and common flavors
wget -qO - http://j.mp/scw-skeleton | FLAVORS=sysvinit,docker-based,common bash -e

# Specific GIT branch
wget -qO - http://j.mp/scw-skeleton | FLAVORS=upstart BRANCH=feature-xxx bash -e

# Use curl
curl -L -q http://j.mp/scw-skeleton | DL=curl bash -e

# Alternative URL
wget -qO - https://raw.githubusercontent.com/scaleway/image-tools/master/install.sh | ... bash -e
```

A running instance can be updated by calling the same commands.
It is planned to to create packages (.deb) for distributions.


# Licensing

© 2014-2015 Scaleway - [MIT License](https://github.com/scaleway/image-tools/blob/master/LICENSE).
A project by [![Scaleway](https://avatars1.githubusercontent.com/u/5185491?v=3&s=42)](https://www.scaleway.com/)
