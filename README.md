ocs-scripts
===========

This repository contains the scripts used to boot an image on [Online.net's cloud services](http://labs.online.net/).
Scripts are built-in official images and some of them are also used in the official Initrd image.

It is planned to to create packages (.deb) for distributions.

Upgrade a running image
-----------------------

```bash
wget -qO - https://raw.githubusercontent.com/online-labs/ocs-scripts/master/upgrade_root.bash | bash
```

Using flavors
-------------

```bash
# upstart
wget -qO - https://raw.githubusercontent.com/online-labs/ocs-scripts/master/upgrade_root.bash | FLAVORS=upstart bash
```

```bash
# sysvinit
wget -qO - https://raw.githubusercontent.com/online-labs/ocs-scripts/master/upgrade_root.bash | FLAVORS=sysvinit bash
```

Using branches
--------------

```bash
# flavor=upstart on branch=feature-xxx
wget -qO - https://raw.githubusercontent.com/online-labs/ocs-scripts/master/upgrade_root.bash | FLAVORS=upstart BRANCH=feature-xxx bash
```
