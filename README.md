Image Tools - Scripts to build images on Online Labs
====================================================

This repository contains the tools, documentations and examples for building, debug and running images on Online Labs.

---

Getting start
-------------

You can look the docker-based build [example](https://github.com/online-labs/image-tools/tree/master/examples)


Official images
---------------

Official images are available when creating a new server

- Distributions
  - [Ubuntu](https://github.com/online-labs/image-ubuntu): Ubuntu with init scripts and common packages (available tags: 14.04, 14.10, 15.04)
  - [Debian](https://github.com/online-labs/image-debian): Debian with init scripts and common packages
- Apps
  - [Docker](https://github.com/online-labs/image-app-docker): Ready-to use docker 1.3.2 + fig + nsenter + gosu + pipework
  - [Ghost](https://github.com/online-labs/image-app-ghost): [Ghost blogging platform](https://ghost.org) InstantApp
  - [Owncloud](https://github.com/online-labs/image-app-owncloud): [Owncloud](http://owncloud.org) InstantApp
  - [Pydio](https://github.com/online-labs/image-app-pydio): [Pydio](https://pyd.io) InstantApp
  - [Wordpress](https://github.com/online-labs/image-app-wordpress): [Wordpress blogging system](https://www.wordpress.com) InstantApp
- Services: this image are not available when creating a new server
  - [Try-it](https://github.com/online-labs/image-service-tryit): The image running on servers used on the [http://labs.online.net/](try-it page). Contains docker and a tty.js daemon to expose a shell on the web
  - [Rescue](https://github.com/online-labs/image-service-rescue): This image is only available using the rescue bootscript and will be fully loaded in RAM at boot

Unofficial images
-----------------

Unofficial images are only available to those who build them.

For the one using the Docker-based builder, they can also be used as a parent image.

- [moul's devbox](https://github.com/moul/ocs-image-devbox): Based on the [official Docker image](https://github.com/online-labs/image-app-docker)
- [mxs' 3.2 perf](https://github.com/aimxhaisse/image-ocs-perf-3.2): Based on the [Ubuntu image](https://github.com/online-labs/image-ubuntu)
- [mxs' 3.17 perf](https://github.com/aimxhaisse/image-ocs-perf-3.17): Based on the [Ubuntu image](https://github.com/online-labs/image-ubuntu)

Builders
--------

We currently have two kind of builders: Docker and Scripts

FIXME

Commands
--------

    # build the image in a rootfs directory
    $ make rootfs

    # build a tarball of the image
    $ make rootfs.tar

    # build a squashfs of the image
    $ make rootfs.sqsh

    # push the rootfs.tar on s3
    $ make publish_on_s3.tar

    # push the rootfs.sqsh on s3
    $ make publish_on_s3.sqsh

    # write the image to /dev/nbd1
    $ make install_on_disk

    # push the image on docker registry
    $ make release

    # clean
    $ make clean

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

Install .mk files
-----------------

    # From a shell
    wget -qO - https://raw.githubusercontent.com/online-labs/image-tools/master/install.sh | bash

Of in a Makefile ([example](https://github.com/online-labs/image-tools/blob/master/examples/Makefile))

```makefile
## Image tools  (https://github.com/online-labs/image-tools)
all:    docker-rules.mk
docker-rules.mk:
wget -qO - https://raw.githubusercontent.com/online-labs/image-tools/master/install.sh | bash
-include docker-rules.mk
```
