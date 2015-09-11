# Official Image Builder on Scaleway

[![Run on Scaleway](https://img.shields.io/badge/Scaleway-run-69b4ff.svg)](http://cloud.scaleway.com/#/servers/new?image=49eb4659-44a2-4d9c-bcc4-142185379e6e)

Scripts to build the official Image Builder on Scaleway

![](http://s10.postimg.org/fw962sxkp/builder.png)
---

**This image is meant to be used on a C1 server.**

We use the Docker's building system and convert it at the end to a disk image that will boot on real servers without Docker. Note that the image is still runnable as a Docker container for debug or for inheritance.

[More info](https://github.com/scaleway/image-tools)


## How to build a custom image using [scw](https://github.com/scaleway/scaleway-cli)

**My custom image's description**
- based on the official [Ubuntu Vivid](https://github.com/scaleway/image-ubuntu)
- with `cowsay` pre-installed

---

##### 1. Making the environment

```console
root@yourmachine> scw run --name="buildcowsay" builder
Welcome to the image to build other images on Scaleway' C1.

 * Kernel:           GNU/Linux 4.0.5-235 armv7l
 * Distribution:     An image to build other images (2015-08-06) on Ubuntu 15.04
 * Internal ip:      X.X.X.X
 * External ip:      X.X.X.X
 * Disk /dev/nbd0:   buildcowsay-scw-image-builder-1.0-2015-08-06_15:20 (l_ssd 50G)
 * Uptime:           19:44:48 up 1 min,  0 users,  load average: 0.44, 0.13, 0.05

Links
 * Documentation:    https://scaleway.com/docs
 * Community:        https://community.scaleway.com
 * Image source:     https://github.com/scaleway/image-tools/tree/master/image-builder

Docker 1.7.1 is running using the 'aufs' storage driver.
Installed tools: docker-compose, nsenter, gosu and pipework are installed.
Getting started with Docker on C1: https://community.cloud.online.net/t/383?u=manfred.

*****************************************************************************

   Welcome on the image-builder.
   Here, you will be able to craft your own images.

   To configure your environment please run:

   $> image-builder-configure

*****************************************************************************

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

root@buildcowsay> image-builder-configure
Login (cloud.scaleway.com):                     # yourmail
Password:                                       # yourpassword
root@buildcowsay> mkdir vivid-cowsay
root@buildcowsay> cp Makefile vivid-cowsay
root@buildcowsay> cd vivid-cowsay
root@buildcowsay> touch Dockerfile
root@buildcowsay> ls -l
total 4
-rw-r--r-- 1 root root   0 Aug 28 15:35 Dockerfile
-rw-r--r-- 1 root root 146 Aug 28 15:19 Makefile
```

##### 2. Generating a Dockerfile

**Copy-Paste** this in your `Dockerfile` [see more](https://docs.docker.com/reference/builder/)
```dockerfile
# base image - ubuntu:vivid
FROM armbuild/scw-distrib-ubuntu:vivid

# install cowsay
RUN apt-get install -y cowsay
```
You can see other Dockerfiles [here](https://github.com/scaleway/image-tools#official-images-built-with-image-tools)

##### 3. Building the custom image
```console
root@buildcowsay> make image_on_local
make[1]: Entering directory '/root/vivid-cowsay'
test -f /tmp/create-image-from-http.sh \
	|| wget -qO /tmp/create-image-from-http.sh https://github.com/scaleway/scaleway-cli/raw/master/examples/create-image-from-http.sh
chmod +x /tmp/create-image-from-http.sh
VOLUME_SIZE=50G /tmp/create-image-from-http.sh http://YOURIP/vivid-cowsay-latest/rootfs.tar
[+] URL of the tarball: http://YOURIP/vivid-cowsay-latest/rootfs.tar
[+] Target name: vivid-cowsay-latest-2015-08-28_20:22
[+] Creating new server in rescue mode with a secondary volume...
[+] Server created: 53f65ff4-8a37-495c-9539-460f7c6facf3
[+] Booting...
Linux image-writer-vivid-cowsay-latest-2015-08-28-20-22 3.2.34-30 #17 SMP Mon Apr 13 15:53:45 UTC 2015 armv7l armv7l armv7l GNU/Linux
[+] Server is booted
[+] Formating and mounting /dev/nbd1...
mke2fs 1.42.9 (4-Feb-2014)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
3055616 inodes, 12207031 blocks
610351 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=0
373 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
	4096000, 7962624, 11239424

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done

[+] /dev/nbd1 formatted in ext4 and mounted on /mnt
[+] Download tarball and write it to /dev/nbd1
[+] Tarball extracted on /dev/nbd1
[+] Stopping the server
[+] Server stopped
[+] Creating a snapshot of nbd1
[+] Snapshot 704cf25a-4641-424d-9c28-1f805f5d6259 created
[+] Creating an image based of the snapshot
[+] Image created: 8eef9fff-f53b-4798-9fd7-54944e1cf998            # YOUR_IMAGE_ID
[+] Deleting temporary server
[+] Server deleted
```
Your custom image is now available [here](https://cloud.scaleway.com/#/images)

##### 4. Running your custom image
```console
root@buildcowsay> scw run --tmp-ssh-key YOUR_IMAGE_ID
root@your_custom_image> cowsay "Hello from my custom vivid"
 ____________________________
< Hello from my custom vivid >
 ----------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

---

## Changelog

### 1.3.0 (2015-09-11)

* Bumped scw to 1.5.0
* Added a local webserver
* Put the generation of the key in rc.local

### 1.2.0 (2015-08-28)

* Bumped scw to 1.4.0
* Improved image-builder-configure

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
