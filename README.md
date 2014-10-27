ocs-scripts
===========

This repository contains the scripts used to boot an image on [Online.net's cloud services](http://labs.online.net/).
Scripts are built-in official images and some of them are also used in the official Initrd image.

It is planned to to create packages (.deb) for distributions.

Upgrade a running image
-----------------------

```bash
tar --strip=2 -C / -xzvf <(wget -qO - https://github.com/online-labs/ocs-scripts/archive/master.tar.gz)
```
