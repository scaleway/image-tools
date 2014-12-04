Image Tools - Scripts to build images on Online Labs
====================================================

This repository contains the tools, documentations and examples for building, debug and running images on Online Labs.

---

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
    
    # push the image on s3
    $ make publish_on_s3.tar
    
    # write the image to /dev/nbd1
    $ make install_on_disk


Official images
---------------

Official images are available when creating a new server

- Distributions
  - [Ubuntu](https://github.com/online-labs/image-ubuntu) (14.04, 14.10, 15.04)
  - [Debian](https://github.com/online-labs/image-debian) (wheezy)
- Apps
  - [Docker](https://github.com/online-labs/image-app-docker)
  - [Ghost](https://github.com/online-labs/image-app-ghost)
  - [Owncloud](https://github.com/online-labs/image-app-owncloud)
  - [Pydio](https://github.com/online-labs/image-app-pydio)
  - [Wordpress](https://github.com/online-labs/image-app-wordpress)
- Services
  - [Try-it](https://github.com/online-labs/image-service-tryit)
  - [Rescue](https://github.com/online-labs/image-service-rescue)

Unofficial images
-----------------

Unofficial images are only available to those who build them.

For the one using the Docker-based builder, they can also be used as a parent image.

- [moul's devbox](https://github.com/moul/ocs-image-devbox): Based on the [official Docker image](https://github.com/online-labs/image-app-docker)
