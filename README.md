# Scaleway Image Toolbox

This repository contains the tools, documentation, examples and content for creating images on [Scaleway](https://www.scaleway.com/).


## Distribution images & Instant Apps

Official Scaleway images are found as git repositories on Github, in two organizations:
* [scaleway](https://github.com/scaleway), which focuses on bases images and distributions, with names prefixed by "image-"
* [scaleway-community](https://github.com/scaleway-community) is dedicated to Instant Apps and ready-to-use images, where names are prefixed with "scaleway-".

Your contributions are welcome !

Your custom images can be anywhere, though, they don't even need to be in repositories.


## Getting started

### Simple images

On Scaleway, images are created by tagging an existing snapshot appropriately. This can be done with the [`scw` CLI tool](https://github.com/scaleway/scaleway-cli) (or alternatively, using the [console](https://cloud.scaleway.com) or directly through [the API](https://developer.scaleway.com)):

```
# Using the scw tool -- this assumes you've already set it up.
# Create a snapshot first:
$ scw commit -v 1 my-server my-snapshot
f3af311c-53f7-4f5d-9252-0bf69f017269

# Now make an image out of it:
$ scw tag --arch=x86_64 --bootscript="mainline 4.14"  my-snapshot my-image
a601dbac-08cb-4af3-9ff6-73b7e8dfd34f

$ scw images
REPOSITORY           TAG                 IMAGE ID            CREATED             REGION              ARCH
user/my-image        latest              a601dbac            5 seconds           [     par1]         [x86_64]
---- snipping all stock images 8< ----
```

### Docker-based images

Using the tools contained in this repository, it is possible to create Scaleway images from Docker images. At its core, this process uses the tools we explored above and is pretty straightforward to use: 
  1. Clone this repository and the repository of the image (if there is one) on a Scaleway instance
  2. In your terminal, navigate to the image-tools directory, and type `make IMAGE_DIR=<the image's directory> scaleway_image`
  3. ???
  4. Profit !

As a first example, let's simply rebuild our Ubuntu Xenial image without changing anything. Note that this is not needed to build your own Docker-based images, and is shown here only for demonstration purposes.

[![asciicast](https://asciinema.org/a/foiok7e9gWnyqKK6HbWQIaAQz.png)](https://asciinema.org/a/foiok7e9gWnyqKK6HbWQIaAQz)

Now that we've had a first taste, let's create a custom image based on Scaleway's Ubuntu image:

[![asciicast](https://asciinema.org/a/qRVW81Ciqd1eeoki3Enyn3X7e.png)](https://asciinema.org/a/qRVW81Ciqd1eeoki3Enyn3X7e)

To recap, here's what's needed for a custom Docker-based image:
  - A Dockerfile with an `ARCH` buildarg, based on any Docker image as long as the `FROM` chain can be traced back to one of Scaleway's official images on the Dockerhub: this is needed so that your custom image will ship with the needed tools, configuration and initialization scripts.
  - An env.mk file, containing metadata for the builder tool. It must be valid makefile syntax and will be included at the beginning of the build process. It must at least set the following variables: `IMAGE_NAME`, `IMAGE_VERSION` and `IMAGE_TITLE` but can also set other information, such as authorship, or extra buildargs for Docker with `BUILD_ARGS`.
  
All the rest is up to you and your creativity ! You can, for example, upload your images to the Dockerhub and start using them as bases for other images.

After building, the image and associated snapshots will be available for use with your account. Note that introducing name conflicts will force you to use the ids to interact with the images through the CLI.

## Building a image step by step

### What image-tools does

1. Building with docker your image
1. Export the file system to a tar via docker export
1. Serve this tar image with minimal python HTTP server ( see `scripts/assets_server.sh` )
1. Boot a instance on Scaleway with target filesystem the http serve
   image
1. The script wait the instance boot-up and ask Scaleway to make
   a snapshot
1. Tag the snapshot as a image

### Prerequisite

  * `docker git jq curl make`
  * scw-cli
  * A scaleway account
  * The build machine must be accessible from the outsite


For the last one you have 4 solutions :
1. Use a scaleway instance for building the image ( can be any kind )
1. Use a server with a public IP
1. Use a SSH reverse tunnel like `ssh -fR public_ip_on_server:8080:localhost:8080 user@aserver`
1. Use `ngrok` but you need to edit the script to have a different port
   from the outside that the one given to the python http server

With 3 last solutions you need to add ENV variables : `make ... SERVE_IP=public_ip_on_server SERVE_PORT=8080 scaleway_image`

### Steps

1. `git clone https://github.com/scaleway/image-tools.git`
1. `git clone https://github.com/scaleway/image-ubuntu.git` can be any
   image you want to build
1. `cd image-tools/`
1. `mktemp -d` Make a directory for the build
1. `make IMAGE_DIR=../image-ubuntu/16.04/ EXPORT_DIR=/tmp/tmp.__to_replace__ scaleway_image`

## Diving below the surface

This section mainly deals with explaining with what happens during the build process. Reading it is not required to be able to create images.

As explained above, images are created by tagging a snapshot. Snapshots capture the state of a server's volume at a certain point in time. The simplicity of this step is what makes it versatile: as long as you can somehow get a server to boot and populate one of its volume with some data, you can create a Scaleway Image.

From there, images can be built in many ways. An example would be to use a server with two volumes, using the first as a system volume and populating the second one as needed (parted, mkfs, debootstrap, pacstrap, etc...) before taking a snapshot of it. Snapshots can only be created when the server is off, though, so you would need to stop it. This can get a bit complicated when you need to build images repeatedly, and requires you to have a dedicated server for the pupose of image creation, so it might be a bit unpractical. 

### The build initrd

To make things easier, we created a lightweight tool for the purpose of image creation in the form of a [special initrd](https://github.com/scaleway/initrd/tree/master/build). An initrd, short for **initial ramdisk**, is a minimal root filesystem that is loaded in memory and mounted from there. In its classic form, an initrd is used to setup the core components of the system and finding the real root filesystem, before surrendering execution to the OS' *init*.

This build initrd is a bit different, as it does not aim to hook into a complete boot and will never call init. It is a intended to be used via a remote boot through preset bootscripts, which are specifications of a kernel + initrd that we feed into [IPXE](http://ipxe.org), the network boot firmware. A server can be assigned a bootscript at creation. The ids of the build bootscripts for different architectures can be found in the `bootscript_ids` file at the root of this project. It can also be accessed with the name "Image creation bootscript".

Detailed information can be found in the initrd's repository, but let's recap its features broadly.

The build initrd offers different methods for building images, which are a collection of scripts. After setting up the network and retrieving metadata, it will use the method specified in the `build_method` parameter given through the metadata environment. Each method requires specific arguments.

The main method used by the image-tools suite is `from-rootfs`, which will retrieve a tarred rootfs from a given location and will apply it to the volume after setting up partitions (Linux, EFI) and their associated filesystem (ext4, fat32). GRUB EFI will then be installed to the partition. For example:

```
$ scw create --bootscript="image creation" --env="build_method=from-rootfs rootfs_url=<url of the rootfs.tar>" 50G
```

Other build methods also exist:
  - `from-qcow2`, which will copy a qcow2 file's content to the device,
  - `unpartitioned-from-rootfs` which will skip the partitions and EFI setup and use the raw device with an ext4 filesystem. Obviously, these images can only be booted remotely.
  
Finally, the build initrd will signal the completion of its job by opening a port given to it through the `signal_build_done_port` parameter, or 22 by default.
