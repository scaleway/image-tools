DOCKER_NAMESPACE =	armbuild/
NAME =			ocs-example
VERSION =		1.2.3
VERSION_ALIASES =	1.2 1 latest
TITLE =			Example Image
DESCRIPTION =		An image with cowsay
SOURCE_URL =		https://github.com/online-labs/image-tools


## Image tools  (https://github.com/online-labs/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - http://j.mp/image-tools | bash
-include docker-rules.mk
## Below you can add custom Makefile commands and overrides
