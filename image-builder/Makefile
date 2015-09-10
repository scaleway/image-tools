DOCKER_NAMESPACE =	armbuild/
NAME =			scw-image-builder
VERSION =		latest
VERSION_ALIASES = 	1.2.0 1.2 1
TITLE =			image-builder
DESCRIPTION =		An image to build other images
SOURCE_URL =		https://github.com/scaleway/image-tools/tree/master/image-builder

IMAGE_VOLUME_SIZE =	150G
IMAGE_BOOTSCRIPT =	docker
IMAGE_NAME =		Image Builder 1.2

## Image tools  (https://github.com/scaleway/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - http://j.mp/scw-builder | bash
-include docker-rules.mk
## Below you can add custom makefile commands and overrides
