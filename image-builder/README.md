# Official Image Builder on Scaleway

[![Run on Scaleway](https://img.shields.io/badge/Scaleway-run-69b4ff.svg)](http://cloud.scaleway.com/#/servers/new?image=49eb4659-44a2-4d9c-bcc4-142185379e6e)

Scripts to build the official Image Builder on Scaleway

![](http://s10.postimg.org/fw962sxkp/builder.png)
---

**This image is meant to be used on a C1 server.**

We use the Docker's building system and convert it at the end to a disk image that will boot on real servers without Docker. Note that the image is still runnable as a Docker container for debug or for inheritance.

[More info](https://github.com/scaleway/image-tools)


:warning: **Documentation incoming** :warning:

---

## Changelog

### 1.1.0 (2015-08-06)

* Improved image-builder-configure (bash now)
* Added the S3_URL in the image-builder-configure script
* Added new script to check if your environment is configured as well

### 1.0.0 (2015-08-05)

This initial version contains:

* Added scw s3cwd
* Added ssh key
* Added script to preconfigure your environment

---

A project by [![Scaleway](https://avatars1.githubusercontent.com/u/5185491?v=3&s=42)](https://www.scaleway.com/)
