# Default variables
NAME ?=                 $(shell basename $(PWD))
VERSION ?=              latest
FULL_NAME ?=            $(NAME)-$(VERSION)
BUILDDIR ?=             /tmp/build/$(FULL_NAME)/
DESCRIPTION ?=          $(TITLE)
DISK ?=                 /dev/nbd1
DOCKER_NAMESPACE ?=     scaleway/
DOC_URL ?=              https://scaleway.com/docs
HELP_URL ?=             https://community.scaleway.com
IS_LATEST ?=            0
S3_URL ?=               s3://test-images
STORE_HOST ?=           store.scw.42.am
STORE_PATH ?=           scw
SHELL_BIN ?=            /bin/bash
SHELL_DOCKER_OPTS ?=
SOURCE_URL ?=           $(shell sh -c "git config --get remote.origin.url | sed 's_git@github.com:_https://github.com/_'" || echo https://github.com/scaleway/image-tools)
TITLE ?=                $(NAME)
VERSION_ALIASES ?=
BUILD_OPTS ?=
HOST_ARCH ?=            $(shell uname -m)
IMAGE_VOLUME_SIZE ?=    50G
IMAGE_NAME ?=           $(NAME)
IMAGE_BOOTSCRIPT ?=     stable
S3_FULL_URL ?=          $(S3_URL)/$(FULL_NAME).tar
ASSETS ?=


# Phonies
.PHONY: build release install install_on_disk publish_on_s3 clean shell re all run
.PHONY: publish_on_s3.tar publish_on_s3.sqsh publish_on_s3.tar.gz travis help


# Default action
all: help


# Actions
help:
	@echo 'General purpose commands'
	@echo ' build                   build the Docker image'
	@echo ' image                   create a Scaleway image (requires a working `scaleway-cli`) from s3 by default'
	@echo ' image_on_s3             create a Scaleway image (requires a working `scaleway-cli`) from s3'
	@echo ' image_on_store          create a Scaleway image (requires a working `scaleway-cli`) from the store'
	@echo ' image_on_local          create a Scaleway image (requires a working `scaleway-cli`) from your local webserver'
	@echo ' rootfs.tar              build and print the location of a rootfs.tar'
	@echo ' info                    print build information'
	@echo ' install_on_disk         write the image to /dev/nbd1'
	@echo ' publish_on_s3           push a tarball of the image on S3 (for rescue testing)'
	@echo ' publish_on_store        push a tarball of the image on store using ssh'
	@echo ' rebuild                 rebuild the Docker image without cache'
	@echo ' release                 push the image on Docker registry'
	@echo ' shell                   open a shell in the image using `docker run`'
	@echo ' test                    run unit test using `docker run` (limited testing)'

build:	.docker-container.built
rebuild: clean
	$(MAKE) build BUILD_OPTS=--no-cache

info:
	@echo "Makefile variables:"
	@echo "-------------------"
	@echo "- BUILDDIR          $(BUILDDIR)"
	@echo "- DESCRIPTION       $(DESCRIPTION)"
	@echo "- DISK              $(DISK)"
	@echo "- DOCKER_NAMESPACE  $(DOCKER_NAMESPACE)"
	@echo "- DOC_URL           $(DOC_URL)"
	@echo "- HELP_URL          $(HELP_URL)"
	@echo "- IS_LATEST         $(IS_LATEST)"
	@echo "- NAME              $(NAME)"
	@echo "- S3_URL            $(S3_URL)"
	@echo "- SHELL_BIN         $(SHELL_BIN)"
	@echo "- SOURCE_URL        $(SOURCE_URL)"
	@echo "- TITLE             $(TITLE)"
	@echo "- VERSION           $(VERSION)"
	@echo "- VERSION_ALIASES   $(VERSION_ALIASES)"
	@echo
	@echo "Computed information:"
	@echo "---------------------"
	@echo "- Docker image      $(DOCKER_NAMESPACE)$(NAME):$(VERSION)"
	@echo "- S3 URL            $(S3_FULL_URL)"
	@echo "- S3 public URL     $(shell s3cmd info $(S3_FULL_URL) | grep URL | awk '{print $$2}')"
	@test -f $(BUILDDIR)rootfs.tar && echo "- Image size        $(shell stat -c %s $(BUILDDIR)rootfs.tar | numfmt --to=iec-i --suffix=B --format=\"%3f\")" || true


image_dep:
	test -f /tmp/create-image-from-http.sh \
		|| wget -qO /tmp/create-image-from-http.sh https://github.com/scaleway/scaleway-cli/raw/master/examples/create-image-from-http.sh
	chmod +x /tmp/create-image-from-http.sh


.PHONY: image_on_s3
image_on_s3: image_dep
	s3cmd ls $(S3_URL) || s3cmd mb $(S3_URL)
	s3cmd ls $(S3_FULL_URL) | grep -q '.tar' || $(MAKE) publish_on_s3.tar
	VOLUME_SIZE="$(IMAGE_VOLUME_SIZE)" IMAGE_NAME="$(IMAGE_NAME)" IMAGE_BOOTSCRIPT="$(IMAGE_BOOTSCRIPT)" /tmp/create-image-from-http.sh $(shell s3cmd info $(S3_FULL_URL) | grep URL | awk '{print $$2}')


.PHONY: image_on_store
image_on_store: image_dep publish_on_store
	VOLUME_SIZE="$(IMAGE_VOLUME_SIZE)" IMAGE_NAME="$(IMAGE_NAME)" IMAGE_BOOTSCRIPT="$(IMAGE_BOOTSCRIPT)" /tmp/create-image-from-http.sh http://$(STORE_HOST)/$(STORE_PATH)/$(NAME)-$(VERSION).tar


.PHONY: image_on_local
image_on_local: image_dep $(BUILDDIR)rootfs.tar
	VOLUME_SIZE="$(IMAGE_VOLUME_SIZE)" IMAGE_NAME="$(IMAGE_NAME)" IMAGE_BOOTSCRIPT="$(IMAGE_BOOTSCRIPT)" /tmp/create-image-from-http.sh http://$(shell oc-metadata --cached PUBLIC_IP_ADDRESS)/$(FULL_NAME)/rootfs.tar


image:	image_on_s3


release: build
	for tag in $(VERSION) $(shell date +%Y-%m-%d) $(VERSION_ALIASES); do \
	  echo docker push $(DOCKER_NAMESPACE)$(NAME):$$tag; \
	  docker push $(DOCKER_NAMESPACE)$(NAME):$$tag; \
	done


install_on_disk: /mnt/$(DISK)
	tar -C /mnt/$(DISK) -xf $(BUILDDIR)rootfs.tar


fast-publish_on_s3.tar: $(BUILDDIR)rootfs.tar
	s3cmd put --acl-public $< $(S3_URL)/$(NAME)-$(VERSION).tar


publish_on_s3.tar: fast-publish_on_s3.tar
	$(MAKE) check_s3 || $(MAKE) publish_on_s3.tar


.PHONY: publish_on_store
publish_on_store: $(BUILDDIR)rootfs.tar
	rsync -Pave ssh $(BUILDDIR)rootfs.tar $(STORE_HOST):store/$(STORE_PATH)/$(NAME)-$(VERSION).tar
	@echo http://$(STORE_HOST)/$(STORE_PATH)/$(NAME)-$(VERSION).tar


check_s3.tar:
	wget --read-timeout=3 --tries=0 -O - $(shell s3cmd info $(S3_FULL_URL) | grep URL | awk '{print $$2}') >/dev/null


publish_on_s3.tar.gz: $(BUILDDIR)rootfs.tar.gz
	s3cmd put --acl-public $< $(S3_URL)/$(NAME)-$(VERSION).tar.gz


publish_on_s3.sqsh: $(BUILDDIR)rootfs.sqsh
	s3cmd put --acl-public $< $(S3_URL)/$(NAME)-$(VERSION).sqsh


fclean: clean
	$(eval IMAGE_ID := $(shell docker inspect -f '{{.Id}}' $(NAME):$(VERSION)))
	$(eval PARENT_ID := $(shell docker inspect -f '{{.Parent}}' $(NAME):$(VERSION)))
	-docker rmi -f $(IMAGE_ID)
	-docker rmi -f $(IMAGE_ID)
	-docker rmi -f $(PARENT_ID)


clean:
	-rm -f $(BUILDDIR)rootfs.tar $(BUILDDIR)export.tar .??*.built
	-rm -rf $(BUILDDIR)rootfs


shell:  .docker-container.built
	test $(HOST_ARCH) = armv7l || $(MAKE) setup_binfmt
	docker run --rm -it $(SHELL_DOCKER_OPTS) $(NAME):$(VERSION) $(SHELL_BIN)


test:  .docker-container.built
	test $(HOST_ARCH) = armv7l || $(MAKE) setup_binfmt
	docker run --rm -it -e SKIP_NON_DOCKER=1 $(NAME):$(VERSION) $(SHELL_BIN) -c 'SCRIPT=$$(mktemp); curl -s https://raw.githubusercontent.com/scaleway/image-tools/master/builder/unit.bash > $$SCRIPT; bash $$SCRIPT'


travis:
	find . -name Dockerfile | xargs cat | grep -vi ^maintainer | bash -n


# Aliases
publish_on_s3: publish_on_s3.tar
check_s3: check_s3.tar
install: install_on_disk
run: shell
re: rebuild


# File-based rules
Dockerfile:
	@echo
	@echo "You need a Dockerfile to build the image using this script."
	@echo "Please give a look at https://github.com/scaleway/image-helloworld"
	@echo
	@exit 1


.docker-container.built: Dockerfile patches $(ASSETS) $(shell find patches -type f) patches/usr/local/bin
	test $(HOST_ARCH) = armv7l || $(MAKE) setup_binfmt
	-find patches -name '*~' -delete || true
	docker build $(BUILD_OPTS) -t $(NAME):$(VERSION) .
	for tag in $(VERSION) $(shell date +%Y-%m-%d) $(VERSION_ALIASES); do \
	  echo docker tag -f $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$$tag; \
	  docker tag -f $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$$tag; \
	done
	docker inspect -f '{{.Id}}' $(NAME):$(VERSION) > $@


patches:
	mkdir patches


$(BUILDDIR)rootfs: $(BUILDDIR)export.tar
	-rm -rf $@ $@.tmp
	-mkdir -p $@.tmp
	tar -C $@.tmp -xf $<
	rm -f $@.tmp/.dockerenv $@.tmp/.dockerinit
	-chmod 1777 $@.tmp/tmp
	-chmod 755 $@.tmp/etc $@.tmp/usr $@.tmp/usr/local $@.tmp/usr/sbin
	-chmod 555 $@.tmp/sys
	-chmod 700 $@.tmp/root
	-mv $@.tmp/etc/hosts.default $@.tmp/etc/hosts || true
	echo "IMAGE_ID=\"$(TITLE)\"" >> $@.tmp/etc/scw-release
	echo "IMAGE_RELEASE=$(shell date +%Y-%m-%d)" >> $@.tmp/etc/scw-release
	echo "IMAGE_CODENAME=$(NAME)" >> $@.tmp/etc/scw-release
	echo "IMAGE_DESCRIPTION=\"$(DESCRIPTION)\"" >> $@.tmp/etc/scw-release
	echo "IMAGE_HELP_URL=\"$(HELP_URL)\"" >> $@.tmp/etc/scw-release
	echo "IMAGE_SOURCE_URL=\"$(SOURCE_URL)\"" >> $@.tmp/etc/scw-release
	echo "IMAGE_DOC_URL=\"$(DOC_URL)\"" >> $@.tmp/etc/scw-release
	mv $@.tmp $@

$(BUILDDIR)rootfs.tar.gz: $(BUILDDIR)rootfs
	tar --format=gnu -C $< -czf $@.tmp .
	mv $@.tmp $@


.PHONY: rootfs.tar
rootfs.tar: $(BUILDDIR)rootfs.tar
	ls -la $<
	@echo $<


$(BUILDDIR)rootfs.tar: $(BUILDDIR)rootfs
	tar --format=gnu -C $< -cf $@.tmp .
	mv $@.tmp $@


$(BUILDDIR)rootfs.sqsh: $(BUILDDIR)rootfs
	mksquashfs $< $@ -noI -noD -noF -noX


$(BUILDDIR)export.tar: .docker-container.built
	-mkdir -p $(BUILDDIR)
	docker run --name $(NAME)-$(VERSION)-export --entrypoint /dontexists $(NAME):$(VERSION) 2>/dev/null || true
	docker export $(NAME)-$(VERSION)-export > $@.tmp
	docker rm $(NAME)-$(VERSION)-export
	mv $@.tmp $@


/mnt/$(DISK): $(BUILDDIR)rootfs.tar
	umount $(DISK) || true
	mkfs.ext4 $(DISK)
	mkdir -p $@
	mount $(DISK) $@


patches/usr/local/bin:
	mkdir -p $@


patches/usr/local/bin/qemu-arm-static: patches/usr/local/bin
	wget --no-check-certificate https://github.com/armbuild/qemu-user-static/raw/master/x86_64/qemu-arm-static -O $@
	chmod +x $@


setup_binfmt: patches/usr/local/bin/qemu-arm-static
	@echo "Configurig binfmt-misc on the Docker(/Boot2Docker) kernel"
	docker run --rm --privileged busybox sh -c " \
	  mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc && \
	  test -f /proc/sys/fs/binfmt_misc/arm || \
	  echo ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/local/bin/qemu-arm-static:' > /proc/sys/fs/binfmt_misc/register \
	"
