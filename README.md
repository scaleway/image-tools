# Scaleway Image Toolbox

This repository contains the tools, documentation, examples and content for creating images on [Scaleway](https://www.scaleway.com/).


## Distribution images & Instant Apps

Official Scaleway images are found as git repositories on Github, in two organizations:
* Distribution images repositories are owned by the [scaleway](https://github.com/scaleway) organization, with names prefixed by "image-"
* Other images repositories, including the Instant Apps, are owned by the [scaleway-community](https://github.com/scaleway-community) organization and are usually named with a "scaleway-" prefix

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
  
All the rest is up to you and your creativity ! You can, for example, upload your images to the Dockerhub and and start using them as bases for other images.

After building, the image and associated snapshots will be available for use with your account. Note that introducing name conflicts will force you to use the ids to interact with the images through the CLI.
