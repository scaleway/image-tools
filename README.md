# Scaleway's images - Toolbox

This repository contains the scripts used to create images on [Scaleway](https://www.scaleway.com/).

See [Building images on Scaleway with Docker](http://www.slideshare.net/manfredtouron/while42-paris13-scaleway) presentation on Slideshare.

For an example of project using **image-tools**, please give a look at the [hello-world app](https://github.com/scaleway/image-helloworld).


## Repository

This repository contains :

- common scripts used in the images (upstart, sysvinit, openrc, common helpers, etc)
- Makefile scripts to build the images


## Images built with **image-tools**

The official images built with [image-tools](https://github.com/scaleway/image-tools) are using this repositoty.

Non-exhaustive list :

- [Ubuntu](https://github.com/scaleway/image-ubuntu) (with FLAVORS=common,upstart,docker-based)
- [Debian](https://github.com/scaleway/image-debian) (with FLAVORS=common,sysvinit,docker-based)
- [ArchLinux](https://github.com/scaleway/image-archlinux) (with FLAVORS=common,systemd,docker-based)
- [OpenSuse](https://github.com/scaleway/image-opensuse) (with FLAVORS=common,systemd,docker-based)
- [Fedora](https://github.com/scaleway/image-fedora) (with FLAVORS=common,systemd,docker-based)
- [Slackware](https://github.com/scaleway/image-slackware) (with FLAVORS=common,docker-based)
- [Alpine Linux](https://github.com/scaleway/image-alpine) (with FLAVORS=common,docker-based)
- [Docker app](https://github.com/scaleway/image-app-docker) (with FLAVORS=common,upstart,docker-based, by inheriting the Ubuntu image)
- ...


## How to download the common scripts on a target image

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
wget -qO - https://raw.githubusercontent.com/scaleway/image-tools/master/scripts/install.sh | ... bash -e
```

A running instance can be updated by calling the same commands.
It is planned to to create packages (.deb) for distributions.


---

A project by [![Scaleway](https://avatars1.githubusercontent.com/u/5185491?v=3&s=42)](https://www.scaleway.com/)
