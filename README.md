OCS scripts
===========

This repository contains the scripts used to boot an image on [Online.net's cloud services](http://labs.online.net/).
Scripts are built-in official images and some of them are also used in the official Initrd image.

It is planned to to create packages (.deb) for distributions.

Why this repository exists ?
----------------------------

Because we create more and more images, and they have lots of common files, so we categorize the kind of files (flavors) and try to prevent duplicates files and issues accross similar images

---

The official images built with [image-tools](https://github.com/online-labs/image-tools) are using this repositoty.

Non-exhaustive list :

- [Ubuntu](https://github.com/online-labs/image-ubuntu) (with FLAVORS=upstart,docker-based)
- [Debian](https://github.com/online-labs/image-debian) (with FLAVORS=sysvinit,docker-based)
- [ArchLinux](https://github.com/online-labs/image-archlinux) (with FLAVORS=systemd,docker-based)
- [OpenSuse](https://github.com/online-labs/image-opensuse) (with FLAVORS=systemd,docker-based)
- [Fedora](https://github.com/online-labs/image-fedora) (with FLAVORS=systemd,docker-based)
- [Slackware](https://github.com/online-labs/image-slackware) (with FLAVORS=docker-based)
- [Alpine Linux](https://github.com/online-labs/image-alpine) (with FLAVORS=docker-based)
- [Docker app](https://github.com/online-labs/image-app-docker) (with FLAVORS=upstart,docker-based, by inheriting the Ubuntu image)
- ...

Upgrade a running image
-----------------------

```bash
wget -qO - http://j.mp/ocs-scripts | bash -e
```

Using flavors
-------------

```bash
# upstart
wget -qO - http://j.mp/ocs-scripts | FLAVORS=upstart bash -e
```

```bash
# sysvinit
wget -qO - http://j.mp/ocs-scripts | FLAVORS=sysvinit bash -e
```

Using branches
--------------

```bash
# flavor=upstart on branch=feature-xxx
wget -qO - http://j.mp/ocs-scripts | FLAVORS=upstart BRANCH=feature-xxx bash -e
```

Using curl
----------

```bash
curl -L -q http://j.mp/ocs-scripts | DL=curl bash -e
```

Alternative url
---------------

```bash
wget -qO - https://raw.githubusercontent.com/online-labs/ocs-scripts/master/upgrade_root.bash | ... bash -e
```
