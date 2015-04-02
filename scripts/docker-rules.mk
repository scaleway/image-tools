# Default variables
BUILDDIR ?=             /tmp/build/$(NAME)-$(VERSION)/
DESCRIPTION ?=          $(TITLE)
DISK ?=                 /dev/nbd1
DOCKER_NAMESPACE ?=     armbuild/
DOC_URL ?=              https://scaleway.com/docs
HELP_URL ?=             https://community.cloud.online.net
IS_LATEST ?=            0
NAME ?=                 $(shell basename $(PWD))
S3_URL ?=               s3://test-images
SHELL_BIN ?=            /bin/bash
SHELL_DOCKER_OPTS ?=
SOURCE_URL ?=           $(shell sh -c "git config --get remote.origin.url | sed 's_git@github.com:_https://github.com/_'" || echo https://github.com/scaleway/image-tools)
TITLE ?=                $(NAME)
VERSION ?=              latest
VERSION_ALIASES ?=
BUILD_OPTS ?=
HOST_ARCH ?=		$(shell uname -m)
IMAGE_VOLUME_SIZE ?=	50G
S3_FULL_URL ?=		$(S3_URL)/$(NAME)-$(VERSION).tar
S3_PUBLIC_URL ?=	$(shell s3cmd info $(S3_FULL_URL) | grep URL | awk '{print $$2}')


# Phonies
.PHONY: build release install install_on_disk publish_on_s3 clean shell re all run
.PHONY: publish_on_s3.tar publish_on_s3.sqsh publish_on_s3.tar.gz travis


# Default action
all: build


# Actions
build:	.docker-container.built
rebuild:
	rm -f .docker-container.built
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
	@echo "- S3 pubilc URL     $(S3_PUBLIC_URL)"
	@test -f $(BUILDDIR)rootfs.tar && echo "- Image size        $(shell stat -c %s $(BUILDDIR)rootfs.tar | numfmt --to=iec-i --suffix=B --format=\"%3f\")" || true


image:
	s3cmd ls $(S3_FULL_URL) | grep -q '.tar' \
		|| $(MAKE) publish_on_s3.tar
	test -f /tmp/create-image-from-s3.sh \
		|| wget -qO /tmp/create-image-from-s3.sh https://github.com/moul/scaleway-cli/raw/master/examples/create-image-from-s3.sh
	chmod +x /tmp/create-image-from-s3.sh
	VOLUME_SIZE=$(IMAGE_VOLUME_SIZE) /tmp/create-image-from-s3.sh $(S3_PUBLIC_URL)


release: build
	for tag in $(VERSION) $(shell date +%Y-%m-%d) $(VERSION_ALIASES); do \
	  echo docker push $(DOCKER_NAMESPACE)$(NAME):$$tag; \
	  docker push $(DOCKER_NAMESPACE)$(NAME):$$tag; \
	done


install_on_disk: /mnt/$(DISK)
	tar -C /mnt/$(DISK) -xf $(BUILDDIR)rootfs.tar


publish_on_s3.tar: $(BUILDDIR)rootfs.tar
	s3cmd put --acl-public $< $(S3_URL)/$(NAME)-$(VERSION).tar


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
	test $(HOST_ARCH) = armv7l
	docker run --rm -it $(SHELL_DOCKER_OPTS) $(NAME):$(VERSION) $(SHELL_BIN)


test:  .docker-container.built
	test $(HOST_ARCH) = armv7l
	docker run --rm -it -e SKIP_NON_DOCKER=1 $(NAME):$(VERSION) $(SHELL_BIN) -c 'SCRIPT=$$(mktemp); curl -s https://raw.githubusercontent.com/scaleway/image-tools/master/scripts/unit.bash > $$SCRIPT; bash $$SCRIPT'


travis:
	find . -name Dockerfile | xargs cat | grep -vi ^maintainer | bash -n


# Aliases
publish_on_s3: publish_on_s3.tar
install: install_on_disk
run: shell
re: clean build


# File-based rules
Dockerfile:
	@echo
	@echo "You need a Dockerfile to build the image using this script."
	@echo "Please give a look at https://github.com/scaleway/image-helloworld"
	@echo
	@exit 1


.docker-container.built: Dockerfile patches $(shell find patches -type f)
	test $(HOST_ARCH) = armv7l
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
