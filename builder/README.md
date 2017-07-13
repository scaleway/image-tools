# Introduction

If you're looking for explanations about how to use the image builder, you can refer to [its documentation](https://github.com/scaleway/image-builder).
This document is an introduction to the internals behind it.

The current build process uses docker to produce disk images for all supported architectures.
The program in charge of doing so is `docker-rules.mk`, which is downloaded when building an scaleway image.

Using this docker image, it can then create the rootfs that would run on your server and export it to some storage drivers.

## Did you say architecture`s`?
As docker does not natively support building and running images for other architectures, the image builder relies on [docker multiarch](https://hub.docker.com/u/multiarch/) to do so.

multiarch uses `binfmt` to register a hook running the `qemu` emulator with programs meant for architectures different from the host's. Even if it works fairly well, it doesn't always work well enough to perform some operations, so you might have to find to workarounds.

## Well, ok, but how does it *actually* work ?

### Step 1: Generating the architecture-specific docker project

As you might have noticed, the Dockerfiles of multiarch-powered projects have multiple commented `FROM` statements. `docker-rules.mk` chooses the first one matching the target architecture using some sed magic.

The new Dockerfile is then copied to a separate folder, named `tmp-$(ARCH)`, along with `overlay/` and some others.

### Step 2: Building

Using the newly built architecture-specific project, the makefile runs docker to build and tag the image.

The whole build process relies on `qemu`. You can find its binary distribution at `/usr/bin/qemu-$(ARCH)-static` inside the container.

### Step 3: Exporting

The export process works as follows:

 - Create a new machine with some tags telling it to drop a ssh server at the end of initrd
 - Once it's up, connect to it and write the rootfs to the attached image
 - Stop the server
 - Create a snapshot of the attached disk
 - Convert it to an image

 This whole process is performed by [`create-image-from-http.sh`](https://github.com/scaleway/scaleway-cli/blob/master/examples/create-image-from-http.sh).

Exporting to an s3 compatible server is also possible.