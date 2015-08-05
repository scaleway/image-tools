DOCKER_NAMESPACE =	armbuild/
NAME =			scw-image-builder
VERSION =		1.0
VERSION_ALIASES = latest
TITLE =			image-builder
DESCRIPTION =		An image to build other images
SOURCE_URL =		https://github.com/scaleway/image-tools/tree/master/image-builder


## Image tools  (https://github.com/scaleway/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - http://j.mp/scw-builder | bash
-include docker-rules.mk
## Below you can add custom makefile commands and overrides
