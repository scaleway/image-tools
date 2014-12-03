DOCKER_NAMESPACE =	armbuild/
NAME =			ocs-example
VERSION =		1.2.3
VERSION_ALIASES =	1.2 1
IS_LATEST =		1
TITLE =			Example Image
DESCRIPTION =		An image with cowsay
SOURCE_URL =		https://github.com/online-labs/image-tools


## Image tools  (https://github.com/online-labs/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget https://raw.githubusercontent.com/online-labs/image-tools/master/docker-rules.mk
-include docker-rules.mk


## Here you can add custom commands and overrides
