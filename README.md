Image Tools - Scripts to build images on Online Labs
====================================================

This repository contains the tools, documentations and examples for building, debug and running images on Online Labs.

---

Getting start
-------------

You can look the docker-based [hello-world](https://github.com/online-labs/image-helloworld) image.


Official images
---------------

Official images are available when creating a new server

- Distributions
  - [Ubuntu](https://github.com/online-labs/image-ubuntu): Ubuntu with init scripts and common packages (available tags: 14.04, 14.10, 15.04)
  - [Debian](https://github.com/online-labs/image-debian): Debian with init scripts and common packages
  - [Fedora](https://github.com/online-labs/image-fedora): Fedora with init scripts and common packages
  - [Archlinux](https://github.com/online-labs/image-archlinux): Work in progress
  - [Opensuse](https://github.com/online-labs/image-opensuse): Work in progress
  - [Slackware](https://github.com/online-labs/image-slackware): Work in progress
- Apps
  - [Docker](https://github.com/online-labs/image-app-docker): Ready-to use docker with fig, nsenter, gosu and pipework
  - [Ghost](https://github.com/online-labs/image-app-ghost): [Ghost blogging platform](https://ghost.org) InstantApp
  - [Owncloud](https://github.com/online-labs/image-app-owncloud): [Owncloud](http://owncloud.org) InstantApp
  - [Pydio](https://github.com/online-labs/image-app-pydio): [Pydio](https://pyd.io) InstantApp
  - [Wordpress](https://github.com/online-labs/image-app-wordpress): [Wordpress blogging system](https://www.wordpress.com) InstantApp
  - [OpenVPN](https://github.com/online-labs/image-app-openvpn): Work in progress
  - [Seedbox](https://github.com/online-labs/image-app-seedbox): Work in progress
  - [Timemachine](https://github.com/online-labs/image-app-timemachine): Work in progress
  - [Mesos](https://github.com/online-labs/image-app-mesos): Work in progress
- Services: this image are not available when creating a new server
  - [Try-it](https://github.com/online-labs/image-service-tryit): The image running on servers used on the [http://labs.online.net/](try-it page). Contains docker and a tty.js daemon to expose a shell on the web
  - [Rescue](https://github.com/online-labs/image-service-rescue): This image is only available using the rescue bootscript and will be fully loaded in RAM at boot

Unofficial images
-----------------

Unofficial images are only available to those who build them.

For the one using the Docker-based builder, they can also be used as a parent image.

- [moul's devbox](https://github.com/moul/ocs-image-devbox): Based on the [official Docker image](https://github.com/online-labs/image-app-docker)
- [moul's bench](https://github.com/moul/ocs-image-bench): Based on the [official Ubuntu image](https://github.com/online-labs/image-ubuntu)
- [mxs' 3.2 perf](https://github.com/aimxhaisse/image-ocs-perf-3.2): Based on the [Ubuntu image](https://github.com/online-labs/image-ubuntu)
- [mxs' 3.17 perf](https://github.com/aimxhaisse/image-ocs-perf-3.17): Based on the [Ubuntu image](https://github.com/online-labs/image-ubuntu)

Builders
--------

We currently have two kind of builders: Docker and Scripts

Docker-based builder
--------------------

We use the [Docker's building system](https://docs.docker.com/reference/builder/) to build, debug and even run the generated images.

We added some small hacks to let the image be fully runnable on a C1 server without Docker.

FIXME: add technical information about hacks

The advantages are :

- Lots of available base images and examples on the [Docker's official registry](https://registry.hub.docker.com)
- Easy inheritance between images ([app-timemachine](https://github.com/online-labs/image-app-timemachine) image inherits from [app-openvpn](https://github.com/online-labs/image-app-openvpn) image which inherits from [ubuntu](https://github.com/online-labs/image-ubuntu) image)
- Easy debug with `docker run ...`
- A well-known build format file (Dockerfile)
- Docker's amazing builder advantages (speed, cache, tagging system)

Install
-------

The minimal command to install an image on an attached volume :

    # write the image to /dev/nbd1
    $ make install

Commands
--------

    # Clone the hello world docker-based app
    $ git clone https://github.com/online-labs/image-helloworld.git

    # Run the image in Docker
    $ make shell

    # push the rootfs.tar on s3 (requires `s3cmd`)
    $ make publish_on_s3 S3_URL=s3://my-bucket/my-subdir/

    # push the image on docker registry
    $ make release DOCKER_NAMESPACE=myusername

    # remove build directories
    $ make clean

    # remove build directories and docker images
    $ make fclean


Debug commands

    # push the rootfs.tar.gz on s3 (requires `s3cmd`)
    $ make publish_on_s3.tar.gz S3_URL=s3://my-bucket/my-subdir/

    # push the rootfs.sqsh on s3 (requires `s3cmd`)
    $ make publish_on_s3.sqsh S3_URL=s3://my-bucket/my-subdir/

    # build the image in a rootfs directory
    $ make build

    # build a tarball of the image
    $ make rootfs.tar

    # build a squashfs of the image
    $ make rootfs.sqsh

Image check list
----------------

List of features, scripts and modifications to check for proper labs.online.net image creation.

- Add sysctl entry `vm.min_free_kbytes=65536`
- Configure NTP to use internal server.
- Configure SSH to only accept login through public keys and deny environment customization to avoid errors due to users locale.
- Configure default locale to `en_US.UTF-8`.
- Configure network scripts to use DHCP and enable them.
  Although not, strictly speaking, needed since kernel already has IP address and gateway this allows DHCP hooks to be called for setting hostname, etc.
- Install custom DHCP hook for hostname to set entry in `/etc/hosts` for software using `getent_r` to get hostname.
- Install scripts to fetch SSH keys
- Install scripts to fetch kernel modules.
- Install scripts to connect and/or mount NBD volumes.
- Install scripts to manage NBD root volume.
- Disable all physical TTY initialization.
- Enable STTY @ 9600 bps.

Before making the image public, do not forget to check it boots, stops and restarts from the OS without any error (most notably kernel) since a failure could lead to deadlocked instances.

Unit test running instance
--------------------------

At runtime, you can proceed to unit tests by calling

    $ SCRIPT=$(mktemp); curl -s https://raw.githubusercontent.com/online-labs/image-tools/master/unit.bash > $SCRIPT; bash $SCRIPT

Install .mk files
-----------------

    # From a shell
    wget -qO - https://raw.githubusercontent.com/online-labs/image-tools/master/install.sh | bash
    # or
    wget -qO - http://j.mp/image-tools-install | bash

Or from a Makefile ([example](https://github.com/online-labs/image-helloworld/blob/master/Makefile))

```makefile
## Image tools  (https://github.com/online-labs/image-tools)
all:    docker-rules.mk
docker-rules.mk:
wget -qO - https://raw.githubusercontent.com/online-labs/image-tools/master/install.sh | bash
-include docker-rules.mk
```

Licensing
=========

© 2014-2015 Online Labs - [MIT License](https://github.com/online-labs/image-tools/blob/master/LICENSE).
