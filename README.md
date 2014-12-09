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
- [Docker app](https://github.com/online-labs/image-app-docker) (with FLAVORS=upstart,docker-based, by inheriting the Ubuntu image)
- ...

Upgrade a running image
-----------------------

```bash
wget -qO - http://j.mp/ocs-scripts | bash
```

Using flavors
-------------

```bash
# upstart
wget -qO - http://j.mp/ocs-scripts | FLAVORS=upstart bash
```

```bash
# sysvinit
wget -qO - http://j.mp/ocs-scripts | FLAVORS=sysvinit bash
```

Using branches
--------------

```bash
# flavor=upstart on branch=feature-xxx
wget -qO - http://j.mp/ocs-scripts | FLAVORS=upstart BRANCH=feature-xxx bash
```

Alternative url
---------------

```bash
wget -qO - https://raw.githubusercontent.com/online-labs/ocs-scripts/master/upgrade_root.bash | ... bash
```
