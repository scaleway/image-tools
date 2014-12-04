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

- Distributions
  - [Ubuntu](https://github.com/online-labs/image-ubuntu) (14.04, 14.10, 15.04)
  - [Debian](https://github.com/online-labs/image-debian) (wheezy)
- Apps
  - [Wordpress](https://github.com/online-labs/image-app-wordpress)
- Services
  - [Rescue](https://github.com/online-labs/image-service-rescue)
